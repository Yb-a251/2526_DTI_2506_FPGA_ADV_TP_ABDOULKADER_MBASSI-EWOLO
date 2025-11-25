# Schéma du Contrôleur HDMI - Pour Rapport LaTeX

## Description Textuelle (à convertir en schéma)

### 1. Architecture Globale

```
                    ┌─────────────────────────────────────────┐
                    │     HDMI_CONTROLLER (27 MHz)            │
                    │                                         │
i_clk (27MHz) ──────┤► CLK                                    │
i_rst_n ────────────┤► RST_N                                  │
                    │                                         │
                    │  ┌────────────────┐                     │
                    │  │  Compteur H    │                     │
                    │  │  (0 à 857)     │─────► o_x_counter   ├──► (0-719)
                    │  └────────┬───────┘                     │
                    │           │ carry                       │
                    │           ▼                             │
                    │  ┌────────────────┐                     │
                    │  │  Compteur V    │                     │
                    │  │  (0 à 524)     │─────► o_y_counter   ├──► (0-479)
                    │  └────────────────┘                     │
                    │                                         │
                    │  ┌────────────────┐                     │
                    │  │  Logique HSYNC │─────► o_hsync       ├──► (actif bas)
                    │  └────────────────┘                     │
                    │                                         │
                    │  ┌────────────────┐                     │
                    │  │  Logique VSYNC │─────► o_vsync       ├──► (actif bas)
                    │  └────────────────┘                     │
                    │                                         │
                    │  ┌────────────────┐                     │
                    │  │  Logique DE    │─────► o_de          ├──► (actif haut)
                    │  └────────────────┘      o_pixel_visible│
                    │                                         │
                    └─────────────────────────────────────────┘
```

### 2. Détail Compteur Horizontal

```
                 ┌─────────────────────────────────┐
    i_clk ───────┤►CLK                             │
    i_rst_n ─────┤►RST_N   r_h_counter             │
                 │         (0 à 857)               │
                 │                                 │
                 │    ┌─────┐                      │
                 │    │  =  │                      │
    857 ─────────┼────┤ 857?├──┐                   │
                 │    └─────┘  │                   │
                 │             │ '1' si fin ligne  │
                 │             ▼                   │
                 │         ┌──────┐                │
                 │      ┌──┤ MUX  ├── 0            │
                 │      │  └──────┘                │
                 │      │      │                   │
                 │      │      └── r_h_counter + 1 │
                 │      │                          │
                 │      └─────────► r_h_counter    ├───► o_x_counter
                 │                                 │     (si <720)
                 └─────────────────────────────────┘
                                 │
                                 └─► carry → Compteur V
```

### 3. Machine à États (Zones Horizontales)

```
     0                720      736          798        858
     │◄──────Visible───►│◄─FP─►│◄─SYNC────►│◄───BP───►│
     │                  │       │           │          │
     │  Zone affichée   │ Front │  Pulse    │   Back   │
     │  (720 pixels)    │ Porch │  HSYNC    │  Porch   │
     │                  │(16px) │  (62px)   │  (60px)  │
     │                  │       │           │          │
     ├──────────────────┼───────┼───────────┼──────────┤
DE : │████████████████  │       │           │          │ (Data Enable)
     │                  │       │           │          │
HS : │▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│▔▔▔▔▔▔▔│▁▁▁▁▁▁▁▁▁▁▁│▔▔▔▔▔▔▔▔▔▔│ (HSYNC)
     └──────────────────┴───────┴───────────┴──────────┘
                                    
     Même principe pour les lignes verticales (V)
```

### 4. Timings Détaillés

#### Horizontal (1 ligne = 31.7 µs)
```
Pixel :   0                              720  736    798  858
          ├───────────────────────────────┼────┼──────┼────┤
          │         VISIBLE               │ FP │ SYNC │ BP │
          │        (720 pixels)           │16px│ 62px │60px│
          └───────────────────────────────┴────┴──────┴────┘
                    26.67 µs             0.59  2.30  2.22 µs
```

#### Vertical (1 frame = 16.6 ms)
```
Ligne :   0                              480 489   495  525
          ├───────────────────────────────┼───┼─────┼────┤
          │         VISIBLE               │FP │SYNC │ BP │
          │        (480 lignes)           │9  │  6  │ 30 │
          └───────────────────────────────┴───┴─────┴────┘
                    15.24 ms            0.29 0.19  0.95 ms
```

### 5. Logique HSYNC (VHDL → Schéma)

```vhdl
o_hsync <= '0' when (r_h_counter >= 736) and (r_h_counter < 798)
           else '1';
```

**Schéma logique** :
```
    r_h_counter ──┬──┤ >= 736 ├───┐
                  │              AND ├─── NOT ───► o_hsync
                  └──┤ < 798  ├───┘
```

### 6. Adresse Linéaire (Framebuffer)

**Formule** : `addr = y × 720 + x`

**Exemple** :
- Pixel (0, 0) : 0 × 720 + 0 = **0**
- Pixel (100, 50) : 50 × 720 + 100 = **36,100**
- Pixel (719, 479) : 479 × 720 + 719 = **345,599** (dernier pixel)

**Schéma calcul** :
```
    y_counter ──┬─► × 720 ──┐
                │           ├─ ADD ──► o_pixel_address
    x_counter ──┴───────────┘         (0 à 345599)
```

---

## Pour le Rapport LaTeX

### Figure 1 : Architecture Complète (TikZ)

```latex
\begin{tikzpicture}[scale=0.8, transform shape]
    % Bloc principal
    \draw[thick] (0,0) rectangle (8,6);
    \node at (4,5.5) {\textbf{HDMI Controller}};
    
    % Entrées
    \draw[<-] (0,4.5) -- (-1,4.5) node[left] {i\_clk (27 MHz)};
    \draw[<-] (0,4) -- (-1,4) node[left] {i\_rst\_n};
    
    % Compteur H
    \draw (1,3) rectangle (3.5,3.8);
    \node at (2.25,3.4) {Compteur H};
    \node[below] at (2.25,3) {\tiny 0 à 857};
    
    % Compteur V
    \draw (1,2) rectangle (3.5,2.8);
    \node at (2.25,2.4) {Compteur V};
    \node[below] at (2.25,2) {\tiny 0 à 524};
    
    % Carry
    \draw[->, thick] (2.25,3) -- (2.25,2.8);
    \node[right] at (2.3,2.9) {\tiny carry};
    
    % Logique HSYNC
    \draw (4.5,3) rectangle (7,3.8);
    \node at (5.75,3.4) {Gen HSYNC};
    
    % Logique VSYNC
    \draw (4.5,2) rectangle (7,2.8);
    \node at (5.75,2.4) {Gen VSYNC};
    
    % Logique DE
    \draw (4.5,1) rectangle (7,1.8);
    \node at (5.75,1.4) {Gen DE};
    
    % Sorties
    \draw[->] (8,4.5) -- (9,4.5) node[right] {o\_x\_counter};
    \draw[->] (8,4) -- (9,4) node[right] {o\_y\_counter};
    \draw[->] (8,3.4) -- (9,3.4) node[right] {o\_hsync};
    \draw[->] (8,2.4) -- (9,2.4) node[right] {o\_vsync};
    \draw[->] (8,1.4) -- (9,1.4) node[right] {o\_de};
\end{tikzpicture}
```

### Figure 2 : Chronogramme HSYNC (1 ligne)

```latex
\begin{tikzpicture}[scale=0.015]
    % Axe temps
    \draw[->] (0,0) -- (900,0) node[right] {Pixels};
    
    % Zones
    \draw[fill=green!20] (0,1) rectangle (720,3);
    \node at (360,2) {VISIBLE (720)};
    
    \draw[fill=yellow!20] (720,1) rectangle (736,3);
    \node[rotate=90] at (728,2) {\tiny FP};
    
    \draw[fill=red!20] (736,1) rectangle (798,3);
    \node at (767,2) {SYNC};
    
    \draw[fill=blue!20] (798,1) rectangle (858,3);
    \node[rotate=90] at (828,2) {\tiny BP};
    
    % Signal HSYNC
    \draw[thick] (0,6) -- (736,6) -- (736,5) -- (798,5) -- (798,6) -- (858,6);
    \node[left] at (0,5.5) {HSYNC};
    
    % Signal DE
    \draw[thick] (0,9) -- (0,10) -- (720,10) -- (720,9) -- (858,9);
    \node[left] at (0,9.5) {DE};
\end{tikzpicture}
```

### Tableau : Timings HDMI 720x480

```latex
\begin{table}[h]
\centering
\caption{Timings HDMI 720×480 @ 60Hz}
\begin{tabular}{|l|c|c|c|c|c|}
\hline
\textbf{Paramètre} & \textbf{Visible} & \textbf{Front} & \textbf{Sync} & \textbf{Back} & \textbf{Total} \\
\hline
Horizontal (pixels) & 720 & 16 & 62 & 60 & \textbf{858} \\
Vertical (lignes)   & 480 & 9  & 6  & 30 & \textbf{525} \\
\hline
\end{tabular}
\end{table}

\textbf{Fréquences :}
\begin{itemize}
    \item Pixel clock : $f_p = 27$ MHz
    \item Ligne : $f_h = \frac{27 \times 10^6}{858} = 31.5$ kHz
    \item Frame : $f_v = \frac{31.5 \times 10^3}{525} = 60$ Hz
\end{itemize}
```

---

## Équations LaTeX

### Adresse Framebuffer
```latex
\text{addr} = y \times W + x \quad \text{où } W = 720
```

### Condition Data Enable
```latex
\text{DE} = \begin{cases}
1 & \text{si } 0 \leq x < 720 \text{ ET } 0 \leq y < 480 \\
0 & \text{sinon}
\end{cases}
```

### HSYNC (actif bas)
```latex
\text{HSYNC} = \begin{cases}
0 & \text{si } 736 \leq x < 798 \\
1 & \text{sinon}
\end{cases}
```

---

**Utilisation** : Copier ces schémas/équations dans votre rapport LaTeX pour la section "Contrôleur HDMI".

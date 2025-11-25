# Captures nécessaires pour le rapport LaTeX

## Dossier à créer
```
captures/
```

## Liste des fichiers d'images requis

### 1. Simulations ModelSim
- `simulation_encoder.png` : Chronogramme encodeur (signaux A/B, fronts, position)
- `simulation_hdmi.png` : Chronogramme HDMI (compteurs, HSYNC, VSYNC, DE)
- `simulation_hdmi_complete.png` : Vue complète 2 trames

### 2. Quartus
- `quartus_compilation_report.png` : Screenshot Flow Summary (Processing → Compilation Report)
- `timequest_report.png` : Screenshot TimeQuest (Tools → TimeQuest Timing Analyzer)

### 3. Photos matériel
- `carte_de10nano.jpg` : Photo carte avec mezzanine encodeurs
- `encodeur_gauche.jpg` : Gros plan encodeur gauche
- `encodeur_droit.jpg` : Gros plan encodeur droit
- `test_pattern_hdmi.jpg` : Photo écran affichant 8 barres couleur

### 4. Logos ENSEA (si disponibles)
- `logo/logo_ensea.png` : Petit logo pour en-tête (hauteur 1.2cm)
- `logo/gauche-logo.png` : Grand logo page de garde (largeur 5cm)

## Si logos ENSEA non disponibles

Option 1 : Commenter les lignes dans le .tex
```latex
%\fancyhead[L]{\includegraphics[height=1.2cm]{logo/logo_ensea.png}}
%\includegraphics[width=5cm]{logo/gauche-logo.png}
```

Option 2 : Utiliser texte à la place
```latex
\fancyhead[L]{\textbf{ENSEA}}
```

## Pour générer le PDF

### Si toutes les images sont présentes
```bash
pdflatex rapport_telecran.tex
pdflatex rapport_telecran.tex  # 2× pour table des matières
```

### Si images manquantes (draft mode)
```bash
pdflatex "\def\draftmode{1}\input{rapport_telecran.tex}"
```

## Captures ModelSim - Comment faire

### 1. Lancer simulation
```bash
vsim -do sim_hdmi_controller.do
```

### 2. Dans ModelSim
- View → Wave
- Zoom sur zone intéressante
- File → Print... → Print to File (PNG)
- Résolution : 1920x1080 minimum

### 3. Signaux à afficher
**Encodeur** :
- i_clk, i_rst_n
- i_ch_a, i_ch_b
- r_a_ff1, r_a_ff2, r_b_ff1, r_b_ff2
- s_increment, s_decrement
- o_position (format: unsigned)

**HDMI** :
- i_clk (27MHz)
- r_h_counter (0-857)
- r_v_counter (0-524)
- o_hsync, o_vsync, o_de
- o_x_counter, o_y_counter

## Captures Quartus - Comment faire

### Flow Summary
1. Processing → Start Compilation
2. Une fois terminé : Processing → Compilation Report
3. Flow Summary (premier item)
4. Screenshot de la fenêtre

### TimeQuest
1. Tools → TimeQuest Timing Analyzer
2. Double-cliquer sur "Slow 85C Model" → Fmax Summary
3. Screenshot du tableau

## Photos matériel - Conseils

- Éclairage : lumière naturelle ou LED blanche
- Résolution : minimum 1920x1080
- Cadrage : montrer carte + connexions HDMI/USB
- Focus : net sur composants principaux
- Pour test pattern : photo écran full HD, pas de reflets

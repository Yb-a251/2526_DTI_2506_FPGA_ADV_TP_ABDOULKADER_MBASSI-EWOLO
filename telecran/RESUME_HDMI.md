# 📋 Résumé - Contrôleur HDMI Implémenté

## ✅ Ce qui a été fait

### 1. Création du Contrôleur HDMI (hdmi_controller.vhd)
- ✅ Timings **720x480 @ 60Hz** (format 480p standard)
- ✅ Compteurs horizontal (0-857) et vertical (0-524)
- ✅ Génération HSYNC/VSYNC (actifs bas)
- ✅ Signal Data Enable (actif dans zone visible)
- ✅ Sorties position pixel (x_counter, y_counter)
- ✅ Calcul adresse linéaire (y × 720 + x)

### 2. Intégration dans telecran.vhd
- ✅ Déclaration du composant
- ✅ Instanciation avec connexions :
  - Horloge : `s_clk_27` (27 MHz de la PLL)
  - Reset : `s_rst_n` (synchrone avec PLL)
  - Sorties HDMI : HS, VS, DE vers ports de sortie
- ✅ Test pattern : 8 barres verticales de couleur

### 3. Testbench et Simulation
- ✅ hdmi_controller_tb.vhd créé
- ✅ Script ModelSim (sim_hdmi_controller.do)
- ✅ Vérifications automatiques des timings
- ✅ Simulation sur 2 frames complètes

### 4. Documentation
- ✅ GUIDE_HDMI_CONTROLLER.md : Procédure complète
- ✅ FORMAT_COULEUR_RGB.md : Réponse question TP
- ✅ Commentaires dans le code VHDL

---

## 📊 Spécifications Techniques

### Timings HDMI 720x480 @ 60Hz

| Paramètre        | Horizontal | Vertical |
|------------------|------------|----------|
| **Zone visible** | 720 pixels | 480 lignes |
| **Front porch**  | 16 pixels  | 9 lignes   |
| **Sync pulse**   | 62 pixels  | 6 lignes   |
| **Back porch**   | 60 pixels  | 30 lignes  |
| **Total**        | **858**    | **525**    |

### Fréquences
- **Pixel clock** : 27 MHz (généré par PLL)
- **Ligne** : 858 × 37ns = 31.7 µs → 31.5 kHz
- **Frame** : 525 × 31.7µs = 16.6 ms → **60 Hz** ✓

---

## 🧪 Tests à Effectuer

### 1. Simulation (PRIORITAIRE)
```bash
cd c:\Users\Loic\Desktop\ensea\niveau2\fpga\tp\telecran
vsim -do sim_hdmi_controller.do
```

**Vérifier** :
- [ ] r_h_counter : 0 → 857 → 0
- [ ] r_v_counter : 0 → 524 → 0
- [ ] HSYNC bas de 736 à 798 pixels
- [ ] VSYNC bas de 489 à 495 lignes
- [ ] Data Enable actif uniquement quand x<720 ET y<480

### 2. Compilation Quartus
- [ ] Analysis & Synthesis : 0 erreur
- [ ] Compile Design : 0 erreur
- [ ] Vérifier ressources (< 5% ALMs attendu)
- [ ] TimeQuest : slack positif sur s_clk_27

### 3. Test sur Carte
- [ ] Programmer la carte (USB Blaster II)
- [ ] Vérifier écran : 8 barres de couleur visibles
- [ ] Encodeurs : LEDs varient quand on tourne

---

## 🎯 Prochaines Étapes (Ordre du TP)

### Étape 3 : Déplacement d'un Pixel ⏳
**Objectif** : Afficher UN seul pixel blanc qui se déplace avec les encodeurs

**À faire** :
1. Mise à l'échelle encodeurs → pixels écran
   ```vhdl
   s_x_pixel <= to_integer(unsigned(s_left_position)) * 720 / 1024;  -- 10 bits → 720
   s_y_pixel <= to_integer(unsigned(s_right_position)) * 480 / 256;  -- 8 bits → 480
   ```

2. Logique d'affichage pixel unique
   ```vhdl
   if (s_x_pixel = s_x_counter) and (s_y_pixel = s_y_counter) then
       o_hdmi_tx_d <= x"FFFFFF";  -- Blanc
   else
       o_hdmi_tx_d <= x"000000";  -- Noir
   end if;
   ```

3. Tester : tourner encodeur doit déplacer le pixel

### Étape 4 : Mémorisation (Framebuffer) ⏳
**Objectif** : Tracer une ligne en mémorisant les pixels parcourus

**Défis** :
- Taille RAM limitée → Utiliser framebuffer réduit (360×240) ou 1-bit
- Dual-port RAM : Port A écriture (encodeurs), Port B lecture (HDMI scan)

**Composant fourni** : `dpram.vhd`

### Étape 5 : Effacement ⏳
**Objectif** : Bouton pour effacer l'écran (parcourir RAM et écrire '0')

**Solution** : Machine à états (FSM) IDLE → CLEARING → DONE

---

## 📝 Questions TP à Répondre

### ✅ "À quels bits correspondent chaque composante couleur ?"
**Réponse complète** : Voir `FORMAT_COULEUR_RGB.md`

**Résumé** :
- Rouge : bits 23-16 (8 bits)
- Vert : bits 15-8 (8 bits)
- Bleu : bits 7-0 (8 bits)
- Format : RGB888 (24-bit True Color)

### ⏳ "Expliquez ce qu'est une mémoire dual-port"
**À faire** : Lire `dpram.vhd` et documenter dans le rapport

**Réponse attendue** :
- 2 ports indépendants (A et B)
- Accès simultané (lecture/écriture parallèle)
- Port A : écriture encodeurs
- Port B : lecture HDMI scan

---

## 🔧 Commandes Utiles

### Compilation rapide
```bash
# Depuis PowerShell
cd c:\Users\Loic\Desktop\ensea\niveau2\fpga\tp\telecran

# Lancer Quartus (si dans le PATH)
quartus_sh --flow compile telecran
```

### Simulation rapide
```bash
vsim -c -do "do sim_hdmi_controller.do; quit -f"
```

### Vérifier syntaxe VHDL
```bash
quartus_map telecran --analyze_file=hdmi_controller.vhd
```

---

## 📚 Fichiers du Projet

### Nouveaux Fichiers Créés
```
hdmi_controller.vhd           # Contrôleur HDMI (timings)
hdmi_controller_tb.vhd        # Testbench simulation
sim_hdmi_controller.do        # Script ModelSim
GUIDE_HDMI_CONTROLLER.md      # Procédure de test
FORMAT_COULEUR_RGB.md         # Réponse question couleurs
RESUME_HDMI.md                # Ce fichier
```

### Fichiers Modifiés
```
telecran.vhd                  # Intégration hdmi_controller + test pattern
```

### Fichiers Existants (Non Modifiés)
```
encoder.vhd                   # Décodeur encodeur rotatif (OK ✓)
I2C_HDMI_Config.vhd           # Config ADV7513 (OK ✓)
pll/pll.vhd                   # Générateur 27 MHz (OK ✓)
dpram.vhd                     # RAM dual-port (pour plus tard)
telecran.qsf                  # Contraintes pins (OK ✓)
```

---

## ⚠️ Points d'Attention

### 1. Résolution : 720×480, PAS 640×480
Votre `telecran.vhd` utilise 720×480 (format CEA-861 480p).  
Ne pas confondre avec VGA 640×480 !

### 2. Horloge : TOUJOURS 27 MHz
Le contrôleur HDMI **doit** utiliser `s_clk_27` (sortie PLL).  
Jamais `i_clk_50` !

### 3. Reset : Actif bas synchrone
Utiliser `s_rst_n` (signal `locked` de la PLL inversé).  
Attendre que la PLL soit stable avant de démarrer.

### 4. Data Enable Obligatoire
`o_hdmi_tx_de` doit être à '0' pendant les zones de blanking.  
Sinon : artéfacts visuels.

---

## 🎓 Pour le Rapport LaTeX

### Sections à Rédiger

1. **Architecture Contrôleur HDMI** (2-3 pages)
   - Schéma bloc : compteurs H/V + FSM
   - Tableau timings (voir ci-dessus)
   - Équations : addr = y × 720 + x
   - Chronogramme HSYNC/VSYNC sur 2 lignes

2. **Format Couleur RGB** (0.5 page)
   - Schéma répartition bits [23:0]
   - Tableau exemples couleurs
   - Profondeur : 24-bit (16M couleurs)

3. **Résultats Simulation** (1 page)
   - Captures ModelSim : compteurs, HSYNC, VSYNC
   - Validation timings (tableau comparatif)

4. **Résultats Carte** (0.5 page)
   - Photo écran : 8 barres de couleur
   - Consommation ressources FPGA

### Figures à Générer (TikZ ou draw.io)
1. Schéma compteurs H/V avec zones (visible, FP, sync, BP)
2. FSM 4 états : VISIBLE → FP → SYNC → BP
3. Chronogramme : CLK, H_counter, HSYNC sur 1 ligne
4. Architecture complète : PLL → HDMI_ctrl → ADV7513

---

## 🚀 Commencer Maintenant

**Action immédiate** :
```bash
# 1. Simuler
cd c:\Users\Loic\Desktop\ensea\niveau2\fpga\tp\telecran
vsim -do sim_hdmi_controller.do

# 2. Si simulation OK → Compiler Quartus
# (via GUI ou commande ci-dessus)

# 3. Si compilation OK → Programmer carte

# 4. Montrer à l'enseignant les 8 barres de couleur
```

**Bon courage ! 💪**

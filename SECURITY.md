# 🔒 Guía de Seguridad

## ⚠️ IMPORTANTE: Antes de Hacer Push a GitHub

Antes de subir estos dotfiles a un repositorio público, asegúrate de:

### 1. Eliminar Tokens y Credenciales

#### Fish Shell
El archivo `fish/config.fish` NO debe contener tokens directamente.

**✅ CORRECTO:**
```fish
# En ~/.config/fish/secrets.fish (no incluido en git)
set -gx MISE_GITHUB_TOKEN "tu_token_aquí"

# En ~/.config/fish/config.fish
source ~/.config/fish/secrets.fish
```

**❌ INCORRECTO:**
```fish
# NO hagas esto en fish/config.fish
set -gx MISE_GITHUB_TOKEN "ghp_xxxxxxxxxxxx"
```

#### Git Configuration
No incluyas credenciales en archivos de configuración:
```bash
git config --global credential.helper store  # Usa el helper del sistema
```

### 2. Usar el Archivo .env.example

Hemos incluido `.env.example` como plantilla. Para usarlo:

```bash
# Copia el archivo de ejemplo
cp .env.example fish/secrets.fish

# Edita y añade tus tokens reales
nano fish/secrets.fish

# Asegúrate de que secrets.fish está en .gitignore
```

### 3. Revisar el .gitignore

El `.gitignore` ya incluye:
- `fish/secrets.fish`
- `fish/fish_variables`
- `**/*_token*`
- `**/*_secret*`
- `.env` y `.env.local`

### 4. Escanear Antes de Commit

Usa herramientas para detectar secretos:

```bash
# Instalar git-secrets
paru -S git-secrets

# Configurar en el repo
cd ~/dotfiles
git secrets --install
git secrets --register-aws

# Escanear
git secrets --scan
```

O usa [truffleHog](https://github.com/trufflesecurity/trufflehog):
```bash
docker run --rm -v $(pwd):/pwd trufflesecurity/trufflehog:latest filesystem /pwd
```

### 5. Historico de Git

Si ya hiciste commit de un secreto:

```bash
# Opción 1: BFG Repo-Cleaner (recomendado)
paru -S bfg
bfg --replace-text passwords.txt  # archivo con secretos a reemplazar

# Opción 2: git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch fish/config.fish" \
  --prune-empty --tag-name-filter cat -- --all

# Forzar push (CUIDADO: reescribe historia)
git push origin --force --all
```

### 6. Rotar Credenciales Comprometidas

Si accidentalmente expusiste un token:

#### GitHub Token
1. Ve a https://github.com/settings/tokens
2. Elimina el token comprometido
3. Genera uno nuevo
4. Actualiza `fish/secrets.fish`

#### SSH Keys
```bash
# Genera nuevas keys
ssh-keygen -t ed25519 -C "tu@email.com"

# Añade a GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
```

## 🛡️ Mejores Prácticas

### Gestión de Secretos

1. **Nunca** hagas commit de:
   - API tokens
   - Contraseñas
   - SSH keys privadas
   - Certificados
   - Variables de entorno con datos sensibles

2. **Siempre** usa:
   - Variables de entorno
   - Archivos `secrets.fish` no versionados
   - Gestores de contraseñas (pass, bitwarden-cli)
   - Sistemas de gestión de secretos (Vault, SOPS)

### Permisos de Archivos

```bash
# Archivos de secretos deben ser privados
chmod 600 ~/.config/fish/secrets.fish
chmod 600 ~/.ssh/id_*

# Scripts ejecutables
chmod 755 ~/.local/bin/*
chmod 755 install.sh
chmod 755 uninstall.sh
```

### SSH Configuration

En `~/.ssh/config`, evita incluir credenciales directamente:

**✅ CORRECTO:**
```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
```

**❌ INCORRECTO:**
```
Host myserver
    HostName example.com
    User admin
    Password mysecretpassword  # NUNCA hagas esto
```

### GPG para Commits

Firma tus commits con GPG:

```bash
# Generar key GPG
gpg --full-generate-key

# Listar keys
gpg --list-secret-keys --keyid-format=long

# Configurar Git
git config --global user.signingkey TU_KEY_ID
git config --global commit.gpgsign true

# Añadir a GitHub
gpg --armor --export TU_KEY_ID
```

## 🔐 Herramientas Recomendadas

### Gestores de Contraseñas CLI

```bash
# pass (compatible con git)
sudo pacman -S pass

# bitwarden-cli
paru -S bitwarden-cli

# 1Password CLI
paru -S 1password-cli
```

### Uso con Pass

```fish
# En fish/config.fish
set -gx MISE_GITHUB_TOKEN (pass show github/mise-token)
```

### Edad para Encriptación

```bash
# Instalar age
sudo pacman -S age

# Encriptar archivo
age -e -o secrets.fish.age secrets.fish

# Desencriptar
age -d secrets.fish.age > secrets.fish
```

### SOPS (Secrets OPerationS)

```bash
# Instalar SOPS
paru -S sops

# Encriptar
sops -e secrets.fish > secrets.fish.enc

# Editar (desencripta automáticamente)
sops secrets.fish.enc
```

## 📋 Checklist Pre-Commit

Antes de cada commit, verifica:

- [ ] No hay tokens en archivos versionados
- [ ] `.gitignore` incluye archivos sensibles
- [ ] `fish/config.fish` no tiene credenciales
- [ ] Archivos de secrets tienen permisos 600
- [ ] Has revisado `git diff` antes de commit
- [ ] Has ejecutado `git secrets --scan`

## 🚨 Si Expusiste un Secreto

1. **Revocar inmediatamente** el token/credencial
2. **Generar nuevo** token/credencial
3. **Limpiar historial** de git (ver sección 5)
4. **Forzar push** para reescribir historia
5. **Actualizar** en todos los lugares donde se use
6. **Monitorear** por uso no autorizado

## 📚 Recursos

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Git Secrets](https://github.com/awslabs/git-secrets)
- [TruffleHog](https://github.com/trufflesecurity/trufflehog)
- [SOPS](https://github.com/mozilla/sops)
- [Age Encryption](https://github.com/FiloSottile/age)

---

**⚠️ RECUERDA: Una vez que un secreto está en Internet, considéralo comprometido.**

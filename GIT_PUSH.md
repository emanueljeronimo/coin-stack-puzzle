# Subir cambios a GitHub (cuenta emanueljeronimo)

Este proyecto usa una **clave SSH dedicada** y el alias `github-emanuel` (no uses `git@github.com` directo si tenés otra cuenta en el mismo PC).

## Requisitos (una sola vez)

1. Clave pública agregada en GitHub:
   - Cuenta: **Settings → SSH and GPG keys**, o
   - Solo este repo: **Repo → Settings → Deploy keys**
2. Archivo `C:\Users\carol\.ssh\config` con:

```sshconfig
Host github-emanuel
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_ed25519_emanueljeronimo
	IdentitiesOnly yes
```

3. Repositorio vacío en GitHub (sin README si ya commiteaste acá):
   - https://github.com/emanueljeronimo/coin-stack-puzzle

## Probar la conexión

```powershell
ssh -T git@github-emanuel
```

Deberías ver: `Hi emanueljeronimo! You've successfully authenticated...`

## Remoto del proyecto

```powershell
cd "C:\Users\carol\OneDrive\Desktop\PROYECTOS\coin-stack-puzzle"
git remote -v
```

Si hace falta configurarlo:

```powershell
git remote add origin git@github-emanuel:emanueljeronimo/coin-stack-puzzle.git
```

Si ya existe otro `origin`:

```powershell
git remote set-url origin git@github-emanuel:emanueljeronimo/coin-stack-puzzle.git
```

## Flujo habitual (push)

```powershell
cd "C:\Users\carol\OneDrive\Desktop\PROYECTOS\coin-stack-puzzle"
git status
git add .
git commit -m "Describe tu cambio"
git push -u origin main
```

Si la rama local se llama `master`:

```powershell
git push -u origin master
```

O renombrar a `main`:

```powershell
git branch -M main
git push -u origin main
```

## Primera subida (repo nuevo en GitHub)

```powershell
cd "C:\Users\carol\OneDrive\Desktop\PROYECTOS\coin-stack-puzzle"
git branch -M main
git push -u origin main
```

## Clonar en otra máquina (misma cuenta SSH)

```powershell
git clone git@github-emanuel:emanueljeronimo/coin-stack-puzzle.git
```

## Clave privada (no compartir)

`C:\Users\carol\.ssh\id_ed25519_emanueljeronimo`

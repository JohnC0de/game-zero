# Git no Neon Survivor

Este projeto (Godot 4.6) gera bastante coisa automaticamente (caches, imports, builds, reports). A ideia aqui e manter no Git apenas o que e _fonte_ do jogo, e ignorar tudo que e _gerado_.

## Inicializacao rapida

```bash
git init

# (opcional, recomendado) padronizar o nome da branch principal
git branch -M main

# instalar hooks (pre-commit) para rodar ./scripts/validate.sh quando fizer sentido
./scripts/install_git_hooks.sh
```

## O que fica fora do Git

Ja esta no `.gitignore`:

- `.godot/` e `.import/` (cache/import do editor)
- `build/`, `dist/`, `reports/` (saidas do release/validacao)
- `.venv/` (virtualenv do gdtoolkit)

## Hooks (pre-commit)

O hook `pre-commit` (em `.githooks/pre-commit`) roda `./scripts/validate.sh` quando arquivos relevantes forem staged.

Para pular a validacao em um commit especifico:

```bash
SKIP_GODOT_VALIDATE=1 git commit -m "..."
```

## Primeiro commit

```bash
git add -A
git commit -m "chore: initial import"
```

## Remote e tags de release

O workflow `.github/workflows/release.yml` esta configurado para rodar em tags `v*`.

Exemplo:

```bash
git tag -a v0.1.0 -m "v0.1.0"
git push origin main --tags
```

## Observacao sobre arquivos grandes

Se o projeto passar a ter muitos binarios/artefatos pesados (ex: audio/video grandes), vale considerar Git LFS para extensoes como `*.wav`, `*.mp3`, `*.ogg`, `*.mp4`, `*.png` grandes.

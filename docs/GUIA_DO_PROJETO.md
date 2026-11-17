# Guia do Projeto: Audio Transcriber

Este guia explica **o que o projeto faz, como usar e para que serve cada arquivo e pasta**.

Ele tem duas partes:

- **[Parte 1: para quem não programa](#parte-1--para-quem-não-programa)**: o que é, como instalar, como usar e o que fazer quando algo dá errado. Não exige conhecimento técnico.
- **[Parte 2: para programadores](#parte-2--para-programadores)**: arquitetura, fluxo dos dados, API, configuração e a descrição de cada arquivo.

Outros documentos da pasta `docs/`:

- [DOCUMENTACAO.md](DOCUMENTACAO.md): diagnóstico técnico do estado atual, com inconsistências encontradas.
- [PROJETO_E_EVOLUCAO.md](PROJETO_E_EVOLUCAO.md): limitações e roadmap de evolução do produto.

---

# Parte 1 — Para quem não programa

## 1.1 O que é este programa?

O **Audio Transcriber** é um programa que roda **no seu próprio computador** e serve para registrar problemas de TI (informática) de forma rápida:

1. Você **fala** o problema (gravando pelo microfone), **envia um arquivo de áudio** ou **digita** um texto.
2. O programa **transforma a fala em texto** (isso se chama *transcrição*).
3. Se você quiser, uma **inteligência artificial** organiza esse texto em um **relato padronizado**, com:
   - um resumo limpo do problema;
   - a **prioridade** (baixa, média, alta ou crítica);
   - a **origem** provável (frontend, backend, infra, banco ou outro);
   - o endereço (URL) do sistema afetado, se você tiver mencionado.
4. O relato é **salvo como arquivo** na pasta `data/reports/`.

**Privacidade:** a transcrição e a inteligência artificial funcionam no seu computador. O áudio não é enviado para serviços externos. A internet só é usada para instalar o programa e baixar os modelos na primeira vez.

## 1.2 Palavras que aparecem neste guia

| Termo | O que significa |
|---|---|
| **Transcrição** | Converter fala (áudio) em texto escrito. |
| **Whisper** | O "ouvido" do programa: a ferramenta que faz a transcrição. Funciona offline depois de baixada. |
| **Modelo** | Um arquivo grande que contém o "conhecimento" de uma IA. Precisa ser baixado uma vez. |
| **Ollama** | Programa gratuito que roda inteligências artificiais de texto no seu computador. Opcional aqui. |
| **llama3.2** | O modelo de IA de texto usado pelo Ollama para organizar o relato. |
| **FFmpeg** | Ferramenta que converte formatos de áudio (MP3, M4A etc.). Sem ele, só arquivos **WAV** funcionam. |
| **Backend** | A parte "invisível" do programa, que faz o trabalho pesado (transcrever, chamar a IA, salvar). |
| **Interface** (ou frontend) | A tela que você usa no navegador. |
| **PowerShell** | O terminal (tela preta/azul de comandos) do Windows. |
| **localhost** | Endereço que significa "este computador". `http://localhost:8501` abre algo que roda na sua máquina. |
| **`.venv`** | Pasta onde ficam as bibliotecas do Python usadas só por este projeto. É criada automaticamente. |

## 1.3 O que você precisa ter instalado

| Item | Obrigatório? | Para quê | Onde baixar |
|---|---|---|---|
| **Windows 10 ou 11** | Sim (para o script automático) | | |
| **Python 3.10 ou mais recente** (recomendado 3.12) | Sim | O programa é escrito em Python | <https://www.python.org/downloads/>. Na instalação, marque **"Add Python to PATH"**. |
| **Internet** | Na primeira vez | Baixar bibliotecas e o modelo de transcrição | |
| **FFmpeg** | Só para MP3, M4A, OGG, MP4 etc. | Converter áudio | <https://ffmpeg.org/download.html> |
| **Ollama** | Só para organizar o relato com IA | IA local | <https://ollama.com/download> |

Espaço em disco: reserve alguns GB. O modelo de transcrição padrão (`medium`) tem cerca de 1,5 GB, e o modelo `llama3.2` do Ollama, cerca de 2 GB.

## 1.4 Instalar e abrir (passo a passo)

1. **Abra a pasta do projeto** no Explorador de Arquivos.
2. Clique na barra de endereço da janela, digite `powershell` e aperte **Enter**. Um PowerShell abrirá já dentro da pasta.
3. Permita que scripts rodem **somente nesta janela** (não altera nada permanente no Windows):

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

4. Inicie o programa:

   ```powershell
   .\scripts\run_dev.ps1
   ```

   Na primeira vez, isso demora alguns minutos: o script cria a pasta `.venv` e instala todas as bibliotecas. Depois, abre **duas janelas novas**: uma do *backend* e outra da *interface*. **Não feche essas janelas** enquanto estiver usando o programa.

5. Abra no navegador: **<http://localhost:8501>**

Para **fechar o programa**, feche as duas janelas que foram abertas (backend e Streamlit).

### Dica: usar um modelo de transcrição menor

O modelo padrão (`medium`) é mais preciso, mas grande e mais lento. Para começar mais rápido, crie um arquivo chamado **`.env`** (só isso, com o ponto na frente) na pasta do projeto, com este conteúdo:

```dotenv
WHISPER_MODEL_SIZE=small
```

Opções, da mais leve para a mais pesada: `tiny`, `base`, `small`, `medium`. Quanto mais leve, mais rápido e menos preciso.

### Habilitar a IA (opcional)

1. Instale e abra o **Ollama**.
2. Em um PowerShell, baixe o modelo:

   ```powershell
   ollama pull llama3.2
   ```

3. Atualize a página do programa no navegador. Na barra lateral, o indicador **IA** deve aparecer com ✓.

## 1.5 Como usar

A tela tem uma **barra lateral** à esquerda e uma área principal com três abas.

**Barra lateral**

- **Seu nome**: preencha antes de tudo. Sem o nome, o programa não deixa continuar.
- **Backend online / offline**: mostra se a parte invisível está funcionando.
- **Transcrição ✓/✗ | IA ✓/✗**: mostra o que está disponível.

**Abas**

| Aba | Como usar |
|---|---|
| **Gravar** | Clique em **Iniciar gravação**, fale, clique em **Parar gravação**. Ouça o áudio e clique em **Transcrever**. O navegador vai pedir permissão para usar o microfone. |
| **Upload** | Envie um arquivo de áudio (wav, mp3, ogg, flac, m4a, mp4, webm) e clique em **Transcrever**. |
| **Texto** | Digite o problema com suas palavras e clique em **Estruturar Relato** (exige a IA). |

**Depois de transcrever**

1. O texto aparece em uma caixa editável. **Corrija** o que o programa entendeu errado.
2. Clique em **Estruturar Relato** para a IA organizar, ou em **Regravar / Novo** para recomeçar.

**Depois de estruturar**

1. Aparece o **Relato Estruturado** com Prioridade, Origem, Relato e URL afetada, todos editáveis.
2. O relato **já foi salvo** em `data/reports/` no momento em que a IA o gerou.
3. **Confirmar e Salvar** marca o relato como "Corrigido" na tela. Atenção: hoje esse botão **não regrava o arquivo** com as suas edições (é uma limitação conhecida).
4. **Novo relato** limpa a tela para começar outro.

Na primeira transcrição, o programa baixa o modelo Whisper. **Pode levar vários minutos**, parecendo travado. Aguarde; das próximas vezes será rápido.

## 1.6 Onde ficam os resultados

| O quê | Onde |
|---|---|
| Relatos salvos | `data/reports/` (arquivos `.json`, um por relato, com nome no formato `AAAA-MM-DD_xxxxxxxx.json`) |
| Registro de funcionamento (log) | `data/app.log` |
| Modelos de transcrição baixados | `models/whisper/` |

Um arquivo de relato tem este formato (pode ser aberto no Bloco de Notas):

```json
{
  "relator": "Maria",
  "status": "Bruto",
  "prioridade": "alta",
  "data": "2026-11-16T14:30:00",
  "origem": "frontend",
  "url": "https://sistema.empresa.com/login",
  "relato": "Botão de login não responde após digitar a senha.",
  "resposta_dev": null
}
```

## 1.7 Problemas comuns

| Sintoma | O que fazer |
|---|---|
| "não pode ser carregado porque a execução de scripts foi desabilitada" | Rode o comando `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` na mesma janela e tente de novo. |
| "python não é reconhecido" | Instale o Python marcando **Add Python to PATH** e abra um novo PowerShell. |
| Barra lateral mostra **Backend offline** | A janela do backend foi fechada ou deu erro. Leia a mensagem nela e rode `.\scripts\run_dev.ps1` de novo. |
| A primeira transcrição demora muito | O modelo está sendo baixado. Confira a internet e o espaço em disco, ou use `WHISPER_MODEL_SIZE=small` no `.env`. |
| MP3/M4A dá erro | Instale o FFmpeg e confirme que o comando `ffmpeg -version` funciona no PowerShell. Ou use um arquivo WAV. |
| **IA ✗** ou erro "Verifique se o ollama está funcionando" | Abra o Ollama e confirme com `ollama list` que o `llama3.2` aparece. |
| "Porta em uso" / "address already in use" | Já existe uma cópia do programa aberta. Feche as janelas antigas e tente de novo. |

---

# Parte 2 — Para programadores

## 2.1 Visão técnica

| Camada | Tecnologia | Arquivos |
|---|---|---|
| Interface | Streamlit + `streamlit-audiorecorder` | `app/streamlit_app.py`, `app/components/`, `app/state/` |
| API | FastAPI + Uvicorn | `app/main.py` |
| Regras de aplicação | Classes de serviço | `services/` |
| Domínio e motores | Áudio (pydub), STT (faster-whisper / Vosk), NLP por regras, cliente LLM (Ollama) | `core/` |
| Configuração | pydantic-settings + `.env`, logging via YAML | `config/` |
| Persistência | Arquivos JSON | `data/reports/` |
| Execução | PowerShell, Bash, Docker, DDEV | `scripts/`, `Dockerfile`, `.ddev/` |

A interface e a API são **dois processos separados** que conversam por HTTP. A interface é só um cliente: toda a lógica está atrás da API.

## 2.2 Arquitetura e fluxo dos dados

```
┌─────────────────────────────┐
│ Navegador                   │
│ Streamlit :8501             │  app/streamlit_app.py
└──────────────┬──────────────┘
               │ HTTP (requests) → API_URL = http://localhost:8000
┌──────────────▼──────────────┐
│ FastAPI :8000               │  app/main.py
│  GET  /health               │
│  POST /process-audio        │
│  POST /structure-report     │
└──────┬───────────────┬──────┘
       │               │
┌──────▼──────┐  ┌─────▼─────────────┐
│ Pipeline    │  │ AIService         │  services/
│ Service     │  │ ReportService     │
└──────┬──────┘  └─────┬─────────────┘
       │               │
┌──────▼───────────────▼────────────────────────────────┐
│ core/audio/processor   → WAV mono 16 kHz 16-bit       │
│ core/speech_to_text/   → WhisperEngine | VoskEngine   │
│ core/nlp/              → limpeza e correção de termos │
│ core/ai_clients/       → LocalClient (Ollama)         │
│ core/report.py         → dataclass Report             │
└───────────────────────────────────────────────────────┘
```

### Fluxo de áudio (`POST /process-audio`)

1. `app/main.py` lê o upload e chama `PipelineService.run_from_bytes` em uma thread (`asyncio.to_thread`), para não bloquear o event loop.
2. `run_from_bytes` grava os bytes em um arquivo temporário com a extensão original.
3. `run_from_path` chama `core/audio/processor.to_vosk_wav`, que:
   - valida existência, extensão (`SUPPORTED_FORMATS`) e tamanho (`MAX_FILE_SIZE_BYTES` = 500 MB);
   - converte com pydub (usa FFmpeg) para WAV mono, `settings.sample_rate` (16000 Hz), 16 bits.
4. `TranscriptionService` transcreve com o motor escolhido na inicialização:
   - **WhisperEngine** se o pacote `faster_whisper` estiver instalado (caso normal);
   - **VoskEngine** caso contrário (exige modelo em `models/vosk`).
5. `NLPPipeline.process` funde segmentos com menos de 2 palavras, normaliza espaços, corrige termos de TI por regex, capitaliza frases e garante pontuação final.
6. A API devolve texto completo, duração e segmentos.
7. Os arquivos temporários são apagados nos blocos `finally`.

### Fluxo de estruturação (`POST /structure-report`)

1. Retorna **503** se `AIService.is_available()` for falso (Ollama inacessível ou sem o modelo `llama3.2`).
2. `AIService.structure_report_async` envia o prompt de sistema `_SYSTEM_STRUCTURE` + texto ao Ollama, em um `ThreadPoolExecutor` (3 workers).
3. A resposta é lida com `json.loads`. Valores de `prioridade`/`origem` fora das listas permitidas viram `"média"`/`"outro"`.
4. Um `Report` é criado com `status="Bruto"` e salvo por `ReportService.save` em `data/reports/<AAAA-MM-DD>_<8 hex>.json`.
5. A resposta é o dicionário do relato mais a chave `file` com o caminho salvo. Qualquer exceção vira **500**.

## 2.3 API HTTP

Com o backend rodando, a documentação interativa (Swagger) fica em **<http://localhost:8000/docs>**.

### `GET /health`

```json
{ "status": "ok", "transcription_available": true, "ai_available": false }
```

### `POST /process-audio`

`multipart/form-data` com o campo `file`.

```powershell
curl.exe -F "file=@C:\caminho\audio.wav" http://localhost:8000/process-audio
```

Resposta:

```json
{
  "filename": "audio.wav",
  "duration": 4.2,
  "transcription": "O sistema de login não abre.",
  "segments": [
    { "start": 0.0, "end": 4.2, "text": "O sistema de login não abre.", "confidence": -0.21 }
  ]
}
```

`confidence` no Whisper é o `avg_logprob` do segmento (valor negativo; mais perto de 0 é melhor). No Vosk é a média da confiança das palavras (0 a 1).

Erros: 400 para arquivo vazio. Formato não suportado ou arquivo grande demais geram exceção não tratada (500).

### `POST /structure-report`

```powershell
curl.exe -X POST http://localhost:8000/structure-report `
  -H "Content-Type: application/json" `
  -d '{\"text\": \"o botao de login nao funciona\", \"relator\": \"Maria\"}'
```

Resposta: os campos de `Report.to_dict()` mais `file`. Erros: 503 (IA indisponível), 500 (JSON inválido do LLM ou outro erro).

## 2.4 Configuração (`.env`)

`config/settings.py` usa **pydantic-settings**: cada campo pode ser definido por variável de ambiente ou no arquivo `.env` da raiz, com o nome em maiúsculas. O `.env` é ignorado pelo git (`*.env` no `.gitignore`).

| Variável | Padrão | Efeito | Em uso? |
|---|---|---|---|
| `WHISPER_MODEL_SIZE` | `medium` | Tamanho do modelo Whisper (`tiny`, `base`, `small`, `medium`, `large-v3`...) | Sim |
| `WHISPER_MODEL_DIR` | `models/whisper` | Onde o modelo é baixado/cacheado | Sim |
| `WHISPER_DEVICE` | `cpu` | `cpu` ou `cuda` (GPU NVIDIA). O `compute_type` está fixo em `int8`. | Sim |
| `WHISPER_LANGUAGE` | `pt` | Idioma da transcrição | Sim |
| `SAMPLE_RATE` | `16000` | Taxa de amostragem do WAV convertido | Sim |
| `VOSK_MODEL_PATH` | `models/vosk` | Modelo Vosk (fallback) | Só com Vosk |
| `DATA_DIR` | `data` | Base de `reports/`. O log continua fixo em `data/app.log`. | Sim |
| `LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING` ou `ERROR` | Sim |
| `MAX_FILE_SIZE_MB` | `500` | Não usado: o limite real vem de `config/constants.py` | Não |
| `LOCAL_AI_MODEL` | vazio | Não usado: o modelo está fixo em `core/ai_clients/local_client.py` (`MODEL = "llama3.2"`) | Não |
| `HF_TOKEN` | vazio | Reservado (Hugging Face) | Não |
| `ANTHROPIC_API_KEY`, `GROQ_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY` | vazio | Reservadas para um cliente de IA em nuvem que **não foi implementado** | Não |

O Ollama é acessado pelo endereço padrão da biblioteca `ollama` (`http://localhost:11434`). Para outro endereço, defina a variável de ambiente `OLLAMA_HOST`, que a biblioteca lê.

## 2.5 Formas de executar

### Windows, automático

`.\scripts\run_dev.ps1`: cria `.venv`, instala `requirements.txt`, sobe a API em `127.0.0.1:8000`, espera o `/health` responder (até 60 s) e sobe o Streamlit em `127.0.0.1:8501`, cada um em sua janela.

### Windows, manual

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt

# Terminal 1: API
$env:PYTHONPATH = (Get-Location).Path
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload

# Terminal 2: interface
$env:PYTHONPATH = (Get-Location).Path
.\.venv\Scripts\python.exe -m streamlit run app\streamlit_app.py --server.address=127.0.0.1 --server.port=8501
```

Para ativar o ambiente no terminal atual: `.\.venv\Scripts\Activate.ps1`.

`PYTHONPATH` precisa apontar para a raiz: os imports são absolutos a partir dela (`from config.settings import ...`, `from app.components ...`).

### Linux / macOS

`./scripts/run_dev.sh`: cria/ativa `.venv`, instala dependências só quando `requirements.txt` muda, tenta baixar o modelo Whisper (e cai para o Vosk se falhar), sobe a API com `--reload` em segundo plano e o Streamlit em primeiro plano. Variáveis opcionais: `APP_HOST`, `APP_PORT`, `STREAMLIT_HOST`, `STREAMLIT_PORT`.

### Docker

```bash
docker build -t audio-transcriber .
docker run -p 8000:8000 audio-transcriber
```

Sobe **apenas a API**. A imagem não inclui FFmpeg nem Streamlit, e o Ollama do host não é visto como `localhost` dentro do contêiner (use `-e OLLAMA_HOST=http://host.docker.internal:11434`).

### DDEV

`ddev start` sobe o contêiner web padrão do DDEV (configurado como projeto PHP, sem uso) e o serviço `python` definido em `.ddev/docker-compose.python.yaml`, com o código montado em `/app` e `--reload`. A API fica em `http://audio-transcriber.ddev.site:8001` (HTTP) e `:8002` (HTTPS). A interface Streamlit não é iniciada.

## 2.6 Mapa de arquivos e pastas

Legenda de situação: **ativo** = usado pela aplicação; **auxiliar** = ferramenta de apoio; **legado** = sobra de versões anteriores, não usado; **vazio** = reservado para o futuro.

### Raiz

| Arquivo | Situação | Descrição |
|---|---|---|
| `README.md` | ativo | Guia rápido de instalação e uso no Windows. |
| `requirements.txt` | ativo | Dependências Python. Mistura as diretas (`fastapi`, `streamlit`, `faster-whisper`, `ollama`, `pydub`, `vosk`...) com transitivas fixadas. `anthropic`, `openai` e `google-genai` estão listadas, mas não são usadas no código. |
| `pyproject.toml` | vazio | Arquivo de 0 bytes, sem efeito. |
| `Dockerfile` | auxiliar | Imagem `python:3.12-slim` que instala as dependências e roda `uvicorn app.main:app` na porta 8000. |
| `.dockerignore` | auxiliar | Exclui `.venv`, `.git`, `.ddev`, `__pycache__` e `data` da imagem Docker. |
| `.gitignore` | auxiliar | Não versiona `.venv/`, `__pycache__/`, `*.pyc`, `models/`, `.claude/`, `.vscode/`, `*.env`, `data/`. |

### `app/`: pontos de entrada (API e interface)

| Arquivo | Situação | Descrição |
|---|---|---|
| `app/__init__.py` | ativo | Marca `app` como pacote Python. |
| `app/main.py` | ativo | **Entrada da API.** Cria o `FastAPI`, configura o logging e o CORS (aberto, `*`), instancia os serviços uma única vez e define `/health`, `/process-audio` e `/structure-report`. |
| `app/streamlit_app.py` | ativo | **Entrada da interface.** Barra lateral (nome e status do backend), abas Gravar/Upload/Texto, tela de revisão da transcrição e tela do relato. A constante `API_URL` define o endereço da API. A tela é uma máquina de estados simples: se há relato, mostra o relato; senão, se há transcrição, mostra a revisão; senão, mostra as abas (`st.stop()` interrompe o resto da página). |
| `app/components/report_form.py` | ativo | Função `render(report)`: mostra prioridade, origem, relato e URL como campos editáveis e devolve o dicionário atualizado. |
| `app/state/session.py` | ativo | Funções `get_*`/`set_*`/`clear_*` em volta de `st.session_state` (nome do relator, transcrição, relato, áudio gravado). Centraliza as chaves da sessão do Streamlit. |
| `app/routers/` | vazio | Reservado para dividir rotas da API (`APIRouter`). Só tem `.gitkeep`. |
| `.gitkeep` (em várias pastas) | auxiliar | Arquivo vazio que serve só para o git versionar a pasta. |

### `config/`: configuração

| Arquivo | Situação | Descrição |
|---|---|---|
| `config/settings.py` | ativo | Classe `Settings` (pydantic-settings) lida do ambiente e do `.env`; exporta o objeto único `settings`. Valida `log_level`. Ver [2.4](#24-configuração-env). |
| `config/constants.py` | ativo/parcial | Constantes fixas: `SUPPORTED_FORMATS`, `MAX_FILE_SIZE_BYTES` (500 MB), `VOSK_CHUNK_SIZE`, `VOSK_CHANNELS`, `VOSK_SAMPLE_WIDTH`. As constantes `SRT_*`, `MAX_SEGMENT_SILENCE_MS`, `MIN_SEGMENT_DURATION_S` e `SPINNER_TEXT` não são usadas. |
| `config/logging.yaml` | ativo | Formato dos logs: console (simples) e arquivo `data/app.log` com rotação (5 MB, 3 backups). Reduz o ruído de `httpx`, `urllib3`, `streamlit` e `vosk`. |
| `config/logging_setup.py` | ativo | `setup_logging()`: carrega o YAML, aplica `settings.log_level` e cria a pasta `data/`. Chamado no início de `app/main.py`. |

### `core/`: lógica de domínio e motores

| Arquivo | Situação | Descrição |
|---|---|---|
| `core/report.py` | ativo | Dataclass `Report` (relator, relato, prioridade, origem, status, data, url, resposta_dev) e os tipos permitidos (`Prioridade`, `Origem`, `Status`). `to_dict()` gera o JSON salvo. |
| `core/audio/processor.py` | ativo | `validate()` (existência, formato, tamanho), `to_vosk_wav()` (converte para WAV mono 16 kHz 16-bit em arquivo temporário; quem chama apaga) e `get_duration()`. Apesar do nome, o WAV gerado serve para os dois motores. |
| `core/audio/recorder.py` | legado | `AudioRecorder`: salva bytes em arquivo temporário. Não é usado (a gravação é feita no navegador). |
| `core/speech_to_text/base.py` | ativo | Contratos: dataclasses `Segment` (start, end, text, confidence) e `Transcript` (lista de segmentos, `full_text`, `duration`), e a classe abstrata `SpeechToTextEngine` com `transcribe()` e `is_ready()`. |
| `core/speech_to_text/whisper_engine.py` | ativo | `WhisperEngine` com **faster-whisper**: carrega o modelo na primeira transcrição (lazy), `compute_type="int8"`, `vad_filter=True` para ignorar silêncios. **Atenção:** ao ser importado, desativa a verificação de certificados SSL do processo inteiro, para contornar proxies corporativos. |
| `core/speech_to_text/vosk_engine.py` | ativo (fallback) | `VoskEngine`: lê o WAV em blocos, usa `KaldiRecognizer` com tempos por palavra e quebra segmentos em pausas maiores que 0,7 s. Exige modelo em `models/vosk` (`scripts/download_models.py`). |
| `core/nlp/pipeline.py` | ativo | `NLPPipeline.process()`: aplica as funções de `utils.py` a cada segmento e devolve um novo `Transcript`. |
| `core/nlp/utils.py` | ativo | `IT_CORRECTIONS` (regex → termo correto, ex.: "fire wall" → "firewall", "v p n" → "VPN"), `clean_text`, `capitalize_sentences`, `ensure_ending_punctuation`, `merge_short_segments`. É aqui que se adicionam novas correções de vocabulário. |
| `core/ai_clients/base_client.py` | ativo | Classe abstrata `BaseAIClient` com `complete(system, prompt)` e `is_available()`. |
| `core/ai_clients/local_client.py` | ativo | `LocalClient` para o Ollama. `is_available()` consulta a lista de modelos instalados e procura `llama3.2`. `complete()` usa `client.chat`. Modelo fixo na constante `MODEL`. |
| `core/orchestrator.py` | legado | `Orchestrator` para áudio/texto → `Report`. Não é usado e chama `AIService.structure_report`, que não existe mais (só a versão `_async`). |
| `core/__init__.py` e subpastas `__init__.py` | ativo | Marcam os pacotes Python. |

### `services/`: casos de uso

| Arquivo | Situação | Descrição |
|---|---|---|
| `services/pipeline_service.py` | ativo | `PipelineService`: bytes ou caminho → conversão → transcrição → NLP → `Transcript`. Cuida dos arquivos temporários. |
| `services/transcription_service.py` | ativo | `TranscriptionService`: escolhe o motor em `_build_engine()` (Whisper se `faster_whisper` estiver instalado, senão Vosk) e repassa `transcribe()` e `is_ready()`. |
| `services/ai_services.py` | ativo | `AIService`: prompt de sistema `_SYSTEM_STRUCTURE` (define os campos e regras de redação), chamada ao LLM fora do event loop, leitura do JSON e validação de prioridade/origem. |
| `services/report_service.py` | ativo | `ReportService`: `save()` grava o relato em `data/reports/`, `load()` lê um arquivo, `list_all()` lista os relatos (mais recentes primeiro; ainda não exposto na API). |
| `services/__init__.py` | ativo | Marca o pacote. |

### `scripts/`: utilitários

| Arquivo | Situação | Descrição |
|---|---|---|
| `scripts/run_dev.ps1` | ativo | Inicialização no Windows (ver [2.5](#25-formas-de-executar)). |
| `scripts/run_dev.sh` | ativo | Inicialização em Linux/macOS. Menciona um `.env.example` que não existe no repositório (apenas avisa). |
| `scripts/download_models.py` | auxiliar | Baixa e extrai modelos **Vosk** para `models/vosk`. Uso: `python scripts/download_models.py --list` ou `--model small-pt` / `large-pt` / `small-en`. Só necessário se o Vosk for usado. |

### `frontend/`: protótipo antigo (legado)

Versão anterior da interface, **substituída por `app/streamlit_app.py`**. Não é iniciada por nenhum script e não funciona com a API atual (espera um campo `ai_analysis` que a API não devolve; `components/audio_recorder.py` importa um pacote `audio_recorder` que não está instalado). Pode servir de referência histórica ou ser removida.

| Arquivo | Descrição |
|---|---|
| `frontend/app.py` | Interface antiga de gravação e envio, apontando para `ffmpeg.exe` na pasta atual. |
| `frontend/utils.py` | `send_to_backend` e `send_text_to_backend` (clientes HTTP da API). |
| `frontend/components/audio_recorder.py` | Exemplo isolado de gravador. |

### `tests/`: testes (vazio)

`tests/unit/`, `tests/integration/` e `tests/e2e/` existem só com `.gitkeep`. Não há testes automatizados ainda. Bons candidatos para começar: `core/nlp/utils.py` (funções puras), `core/audio/processor.validate` e `services/report_service.py`.

### `data/`: dados gerados (fora do git)

| Item | Descrição |
|---|---|
| `data/reports/` | Relatos salvos em JSON. |
| `data/app.log` | Log da aplicação (com rotação). |
| `data/.gitkeep` | Marca a pasta (a pasta inteira é ignorada pelo git). |

### `models/`: modelos baixados (fora do git, criado sob demanda)

| Item | Descrição |
|---|---|
| `models/whisper/` | Criado automaticamente na primeira transcrição com Whisper. |
| `models/vosk/` | Criado por `scripts/download_models.py`. |

### `docs/`: documentação

| Arquivo | Descrição |
|---|---|
| `docs/GUIA_DO_PROJETO.md` | Este guia. |
| `docs/DOCUMENTACAO.md` | Diagnóstico técnico e lista de inconsistências. |
| `docs/PROJETO_E_EVOLUCAO.md` | Limitações atuais e roadmap. |

### `.ddev/`: ambiente DDEV (auxiliar)

[DDEV](https://ddev.com/) é uma ferramenta de ambientes de desenvolvimento em Docker. Quase tudo nesta pasta é **gerado automaticamente** pelo DDEV.

| Item | Descrição |
|---|---|
| `.ddev/config.yaml` | Configuração do projeto: nome `audio-transcriber`, tipo `php` (padrão do DDEV; o PHP não é usado). |
| `.ddev/docker-compose.python.yaml` | **O único arquivo específico do projeto**: adiciona o serviço `python` que constrói o `Dockerfile` da raiz e roda a API com `--reload`, expondo as portas 8001/8002. |
| `.ddev/.ddev-docker-compose-*.yaml`, `.webimageBuild/`, `.dbimageBuild/` | Gerados pelo DDEV a cada `ddev start`. Não editar. |
| `.ddev/traefik/` | Roteamento e certificados locais gerados pelo DDEV (contém uma chave privada local; não deve ser versionada). |
| `apache/`, `nginx_full/`, `mysql/`, `php/`, `providers/`, `commands/`, `homeadditions/`, `share-providers/`, `xhprof/`, `web-build/`, `db-build/`, `web-entrypoint.d/`, `addon-metadata/` | Modelos e exemplos padrão do DDEV, sem uso neste projeto. |

### Pastas geradas automaticamente

| Pasta | Descrição |
|---|---|
| `.venv/` | Ambiente virtual Python com as bibliotecas instaladas. Pode ser apagada; `run_dev.ps1` recria. |
| `__pycache__/` | Bytecode compilado do Python. Pode ser apagado a qualquer momento. |
| `.git/` | Histórico do git. |

## 2.7 Como estender

| Quero... | Onde mexer |
|---|---|
| Corrigir mais termos técnicos na transcrição | Adicionar pares regex → termo em `IT_CORRECTIONS` (`core/nlp/utils.py`). |
| Trocar o modelo do Ollama | Constante `MODEL` em `core/ai_clients/local_client.py` (ou fazê-la ler `settings.local_ai_model`). |
| Mudar os campos do relato | `core/report.py` (dataclass), `_SYSTEM_STRUCTURE` e validação em `services/ai_services.py`, formulário em `app/components/report_form.py`. |
| Adicionar prioridades/origens | Manter sincronizados `core/report.py`, `_ORIGENS_VALIDAS`/`_PRIORIDADES_VALIDAS` em `services/ai_services.py` e `PRIORIDADES`/`ORIGENS` em `app/components/report_form.py`. |
| Usar outro provedor de IA | Criar uma subclasse de `BaseAIClient` em `core/ai_clients/` e usá-la em `AIService.__init__`. As chaves já existem em `settings.py`. |
| Usar outro motor de transcrição | Criar uma subclasse de `SpeechToTextEngine` em `core/speech_to_text/` e registrá-la em `_build_engine()` (`services/transcription_service.py`). |
| Criar novos endpoints | `app/main.py` ou, de forma organizada, um `APIRouter` em `app/routers/` incluído com `app.include_router(...)`. |
| Mudar portas | Comandos em `scripts/run_dev.ps1` e a constante `API_URL` em `app/streamlit_app.py`. |
| Usar GPU NVIDIA | `WHISPER_DEVICE=cuda` no `.env` (exige CUDA/cuDNN instalados). |

## 2.8 Limitações conhecidas

Resumo; detalhes em [DOCUMENTACAO.md](DOCUMENTACAO.md).

- "Confirmar e Salvar" não regrava o JSON em disco; as edições ficam só na sessão.
- O LLM precisa responder JSON puro; se vier com texto extra, a API devolve 500.
- O prompt enviado contém um `"..."` literal antes do texto do usuário (`services/ai_services.py`).
- `whisper_engine.py` desativa a verificação SSL globalmente.
- CORS aberto e sem autenticação: use apenas em rede confiável.
- Sem testes automatizados; `pyproject.toml` vazio.
- `core/orchestrator.py`, `core/audio/recorder.py` e `frontend/` são código legado.

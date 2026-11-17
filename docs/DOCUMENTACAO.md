# Documentação: Audio-Transcriber

Pergunta respondida: **O que esse projeto faz em sua configuração atual de arquivos e pastas?**

## 1. Visão geral

O projeto é uma aplicação local, em português, para registrar **relatos de problemas de TI**. O fluxo é este:

1. O usuário grava ou envia um áudio, ou digita um texto.
2. O áudio é transcrito (Whisper, com Vosk como alternativa) e passa por uma limpeza de texto.
3. Um LLM local (Ollama, modelo `llama3.2`) transforma o texto em um relato JSON estruturado, com prioridade, origem e URL.
4. O relato é salvo em `data/reports/*.json`.

Tecnologias:
- **Backend:** FastAPI e uvicorn.
- **Interface:** Streamlit, com `streamlit-audiorecorder`.
- **Áudio:** pydub, que precisa do FFmpeg.
- **Transcrição:** faster-whisper (padrão) e vosk (fallback).
- **IA:** ollama.
- **Configuração:** pydantic-settings, lendo o `.env`.

O repositório tem um único commit ("first commit"). Há alterações não commitadas em `README.md`, e `.ddev/`, `.dockerignore` e `Dockerfile` não estão versionados.

## 2. Árvore comentada (sem .git, .venv, `__pycache__`)

```
Audio-Transcriber-main/
├─ README.md                  Guia em PT-BR para Windows (script run_dev.ps1, Whisper, Ollama)
├─ Dockerfile                 python:3.12-slim, pip install, CMD uvicorn app.main:app :8000
├─ .dockerignore              .venv, .git, .ddev, __pycache__, data
├─ .gitignore                 .venv, __pycache__, models/, .claude/, .vscode/, *.env, data/
├─ requirements.txt           Dependências fixadas (ver lacunas)
├─ pyproject.toml             VAZIO (0 bytes)
├─ app/
│  ├─ main.py                 API FastAPI (ponto de entrada do backend)
│  ├─ streamlit_app.py        Interface Streamlit (ponto de entrada da UI)
│  ├─ components/report_form.py  Formulário editável do relato estruturado
│  ├─ state/session.py        Getters e setters de st.session_state
│  ├─ routers/ (.gitkeep)     Vazio
│  └─ components/.gitkeep, state/.gitkeep
├─ config/
│  ├─ settings.py             Settings (Whisper, chaves de IA, log, tamanho máximo)
│  ├─ constants.py            Formatos suportados, parâmetros Vosk e SRT
│  ├─ logging_setup.py, logging.yaml  Logging para data/app.log
├─ core/
│  ├─ report.py               Dataclass Report (relator, relato, prioridade, origem, status, data, url, resposta_dev)
│  ├─ orchestrator.py         Orchestrator (áudio ou texto até Report)
│  ├─ ai_clients/             base_client.py (ABC) e local_client.py (Ollama, MODEL="llama3.2")
│  ├─ audio/                  processor.py (to_vosk_wav via pydub), recorder.py
│  ├─ nlp/                    pipeline.py e utils.py (limpeza, correção de termos de TI, pontuação)
│  └─ speech_to_text/         base.py, whisper_engine.py, vosk_engine.py
├─ services/
│  ├─ ai_services.py          AIService: prompt de sistema e parse do JSON
│  ├─ pipeline_service.py     Converte para WAV, transcreve e aplica NLP
│  ├─ transcription_service.py  Escolhe Whisper; se faster_whisper não estiver instalado, usa Vosk
│  └─ report_service.py       Salva e lista JSON em data/reports
├─ frontend/                  UI ANTIGA (app.py, utils.py, components/audio_recorder.py)
├─ scripts/
│  ├─ run_dev.ps1             Cria .venv, instala dependências, sobe backend (8000) e Streamlit (8501)
│  ├─ run_dev.sh              Equivalente em shell
│  └─ download_models.py      Baixa modelos Vosk para models/vosk
├─ data/                      app.log, reports/ (vazio), .gitkeep
├─ tests/{unit,integration,e2e}/  Só .gitkeep, sem testes
└─ .ddev/                     Configuração do DDEV
   ├─ config.yaml             name: audio-transcriber, type: php, php 8.3, nginx-fpm, docroot ""
   ├─ docker-compose.python.yaml  Serviço "python" customizado
   ├─ .ddev-docker-compose-*.yaml, .webimageBuild/, .dbimageBuild/  Gerados pelo DDEV
   ├─ traefik/ (certificado e config do host audio-transcriber)
   └─ apache/, nginx_full/, mysql/, php/, providers/, commands/, homeadditions/, share-providers/, xhprof/  Templates padrão do DDEV, sem uso real
```

## 3. Funcionamento

**Endpoints** (`app/main.py`, CORS aberto):

| Endpoint | O que faz |
|---|---|
| `GET /health` | Retorna `transcription_available` e `ai_available`. |
| `POST /process-audio` | Recebe upload, converte para WAV 16 kHz (`core/audio/processor.py`), transcreve e aplica NLP. Retorna texto e segmentos com início, fim e confiança. |
| `POST /structure-report` | Recebe `{text, relator}`. O Ollama devolve um JSON, que é validado (prioridade e origem inválidas viram `"média"` e `"outro"`). O relato é salvo em `data/reports/<data>_<uuid>.json`. Retorna 503 se o Ollama ou o modelo `llama3.2` estiver indisponível. |

**Interface** (`app/streamlit_app.py`), chamando `API_URL = http://localhost:8000`:
- Abas **Gravar**, **Upload** e **Texto**.
- Uma tela para revisar a transcrição.
- Um formulário editável com prioridade, origem, relato e URL.
- O botão "Confirmar e Salvar" só muda o status para "Corrigido" na sessão. Ele **não regrava o arquivo em disco**.

**Dependências externas:**
- **Whisper:** o modelo (padrão `medium`, CPU, int8, idioma `pt`) é baixado na primeira execução para `models/whisper`. O `WhisperEngine` desativa a verificação SSL (`ssl._create_unverified_context`), por causa de proxies corporativos.
- **Ollama:** roda localmente e usa o modelo fixo `llama3.2`.
- **FFmpeg:** necessário para qualquer formato que não seja WAV.

**Execução no Windows (fluxo documentado):**
- Rode `.\scripts\run_dev.ps1`.
- A interface fica em http://localhost:8501, a API em :8000/docs e o health em :8000/health.

## 4. Docker e DDEV (configuração atual)

- **Dockerfile:** build da imagem Python que sobe só o **backend** FastAPI em `:8000`. Ele não instala FFmpeg e não sobe o Streamlit.
- **`.ddev/config.yaml`:** projeto `type: php`, PHP 8.3, nginx-fpm, `docroot: ""`. Nada de PHP é usado.
- **`.ddev/docker-compose.python.yaml`:**
  - Adiciona o serviço `python`, construído com o `Dockerfile` da raiz.
  - Monta `../:/app` e roda `uvicorn app.main:app --reload`, observando `app`, `core`, `services` e `config`.
  - Define `HTTP_EXPOSE=8001:8000` e `HTTPS_EXPOSE=8002:8000`, ou seja, a API fica nas portas 8001 e 8002 do host DDEV.
- **Execução:** `ddev start` sobe o container web (PHP/nginx) e o serviço Python com a API.
- **Resultado:** só o backend sobe. Não há Streamlit, Ollama nem FFmpeg no container.

## 5. Inconsistências e lacunas

1. **README × Docker/DDEV:** o README descreve só o fluxo Windows e `.venv`. Não menciona `Dockerfile`, `.dockerignore` nem DDEV, que são recentes e não versionados.
2. **DDEV usa o tipo errado:** o `config.yaml` é `type: php` com um serviço Python anexado. Para um projeto sem PHP, `type: generic` ou um compose próprio seria mais coerente. O webserver PHP/nginx não serve nada útil, porque o docroot é a raiz do projeto e não há `index.php`.
3. **Streamlit ausente no container:** a UI (`API_URL=localhost:8000`) não roda no Docker/DDEV. Dentro de containers, `localhost` aponta para o próprio container. As portas expostas (8001/8002) também não batem com o `API_URL` fixo.
4. **Ollama inacessível no container:** `LocalClient` usa `ollama.Client()` com o host padrão (`localhost:11434`), então dentro do Docker a IA ficará indisponível (503) sem configurar `OLLAMA_HOST`. Relatórios e log ficam só no volume montado, já que `data` está no `.dockerignore`.
5. **FFmpeg ausente no Dockerfile:** só WAV funciona, e mesmo assim o `pydub` pode reclamar sem ffmpeg (suposição, não testado).
6. **Código quebrado:**
   - `core/orchestrator.py` chama `AIService.structure_report`, que **não existe**. Só existe `structure_report_async`, e o `Orchestrator` não é usado em lugar nenhum.
   - O prompt em `services/ai_services.py` é `prompt=f"...\n\n{text}"`, com reticências literais, o que parece um resíduo de edição.
   - `AIService.structure_report_async` lança "Nenhuma chave de IA configurada no .env", mas na prática só usa o Ollama.
7. **Configurações mortas:** `settings.py` tem chaves `anthropic/groq/openai/gemini` e o comentário "FallbackClient: Anthropic → Groq → OpenAI → Gemini", mas esse cliente não existe. `local_ai_model` e `hf_token` também não são usados, porque o modelo está fixo em `LocalClient.MODEL`. `anthropic`, `openai` e `google-genai` estão em `requirements.txt` sem uso.
8. **`frontend/` obsoleto e quebrado:**
   - `frontend/app.py` espera `result["ai_analysis"]`, que o backend não devolve.
   - Ele cita Vosk e usa `from utils import ...`.
   - `frontend/components/audio_recorder.py` importa `audio_recorder`, que não é o pacote instalado (`audiorecorder`).
9. **Arquivos vazios ou sem uso:**
   - `pyproject.toml` tem 0 bytes.
   - `app/routers/` e `tests/` só têm `.gitkeep`, ou seja, não há testes.
   - `core/audio/recorder.py` e `config/constants.py` (SRT) parecem sobras do uso com Vosk.
10. **`requirements.txt` pesado e frágil:** mistura dependências diretas e transitivas fixadas, com versões que parecem futuras ou incomuns (numpy 2.4.4, pandas 3.0.2, fastapi 0.135.3, starlette 1.0.0, protobuf 7.34.1). Isso pode falhar na instalação (não verificado). Inclui `colorama`, que só faz sentido no Windows. O README exige Python 3.10 ou mais recente, mas as versões fixadas sugerem 3.12, que é a do Dockerfile e a do `.venv`.
11. **Persistência e robustez:** "Confirmar e Salvar" não persiste as edições. `os.unlink(wav_path)` em `PipelineService` pode falhar se a conversão não gerar o arquivo. O CORS está com `*`. O `scripts/download_models.py` baixa modelos Vosk para `models/vosk`, mas o fluxo padrão usa Whisper.
12. **Higiene do repositório:** `.venv/` e `__pycache__/` estão no diretório (ignorados pelo git). Há um certificado e uma chave privada em `.ddev/traefik/certs/`, locais e gerados pelo DDEV, que não devem ser versionados. `data/app.log` mostra o uso do `WhisperEngine` em 11/11 e 16/11, então a aplicação já foi executada.

## Resposta curta

Na configuração atual, o projeto é um **transcritor de áudio para relatos de TI**: FastAPI (`app/main.py`) mais uma interface Streamlit (`app/streamlit_app.py`), com transcrição pelo Whisper e estruturação do relato pelo Ollama (`llama3.2`), salvando JSON em `data/reports/`. O fluxo suportado e documentado é o do Windows com `scripts\run_dev.ps1`. O `Dockerfile` e o `.ddev/` são adições recentes que só sobem o **backend** da API (porta 8000 no container, 8001/8002 no DDEV), sem a interface, sem Ollama e sem FFmpeg. O README não os cobre.

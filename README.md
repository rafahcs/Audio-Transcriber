# Audio Transcriber

Aplicação local para gravar ou enviar áudio, transcrever em português e, opcionalmente, organizar o texto em um relato de suporte de TI.

## Requisitos

- Windows 10/11 e Python 3.10 ou mais recente.
- Conexão com a internet na primeira instalação e no primeiro uso do Whisper, para baixar as dependências e o modelo de transcrição.
- Ollama é opcional: necessário apenas para organizar relatos com IA.
- FFmpeg é necessário para converter formatos como MP3, M4A, OGG e MP4. Arquivos WAV podem ser usados sem ele.

## Iniciar no Windows

Abra o PowerShell na pasta do projeto. Se o Windows bloquear a execução do script, permita scripts apenas nesta janela:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Inicie a aplicação:

```powershell
.\scripts\run_dev.ps1
```

O script cria o ambiente Python `.venv` se necessário, instala as dependências e abre janelas separadas para o backend e a interface. Acesse:

- Interface: <http://localhost:8501>
- Documentação e teste interativo da API: <http://localhost:8000/docs>
- Verificação do backend: <http://localhost:8000/health>

Para encerrar, feche as janelas do backend e do Streamlit.

## Primeiro teste

1. Abra <http://localhost:8501> e informe seu nome na barra lateral.
2. Na aba **Texto**, escreva uma descrição curta e use **Estruturar Relato**; ou grave/envie um áudio e clique em **Transcrever**.
3. Na primeira transcrição, o Whisper baixa o modelo configurado. Aguarde o download terminar; os próximos usos reaproveitam os arquivos baixados.
4. Confira `/health`: `status: ok` indica que o backend está respondendo.

O modelo padrão é `medium`, que pode demorar para baixar e exige mais espaço. Para começar com um modelo menor, crie um arquivo `.env` na raiz do projeto com:

```dotenv
WHISPER_MODEL_SIZE=small
```

Também é possível usar `base` ou `tiny` para downloads menores e mais rápidos, com possível redução na qualidade da transcrição.

## Habilitar a organização com IA (opcional)

A transcrição funciona sem Ollama. Para estruturar textos e transcrições com IA, instale o [Ollama](https://ollama.com/download), abra-o e baixe o modelo usado pelo projeto:

```powershell
ollama pull llama3.2
```

Depois, atualize a página. O indicador **IA** na barra lateral deve aparecer habilitado. Se o Ollama não estiver disponível, a interface ainda permite testar a transcrição, mas não organizar o relato com IA.

## Iniciar manualmente

Se preferir não usar o script, abra dois terminais PowerShell na pasta do projeto.

No primeiro terminal, crie o ambiente (uma única vez) e instale as dependências:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Inicie o backend nesse terminal:

```powershell
$env:PYTHONPATH = (Get-Location).Path
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

No segundo terminal, inicie a interface:

```powershell
.\.venv\Scripts\python.exe -m streamlit run app\streamlit_app.py --server.address=127.0.0.1 --server.port=8501
```

## Problemas comuns

- **O backend não inicia:** confira a mensagem na janela do backend e execute novamente `.\scripts\run_dev.ps1` para verificar/instalar dependências.
- **A transcrição demora na primeira vez:** o Whisper ainda está baixando o modelo. Confira a conexão e o espaço em disco; use `WHISPER_MODEL_SIZE=small` para reduzir o download.
- **MP3/M4A não abre:** instale o FFmpeg e confirme que `ffmpeg` está disponível no `PATH`. WAV é uma alternativa para testar sem essa instalação.
- **IA aparece indisponível:** confirme que o Ollama está aberto e que `ollama list` mostra o modelo `llama3.2`.
- **Porta em uso:** encerre a instância anterior ou altere a porta no comando do backend e atualize `API_URL` em `app\streamlit_app.py`.

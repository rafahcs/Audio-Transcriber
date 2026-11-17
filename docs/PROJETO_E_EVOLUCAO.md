# Audio Transcriber: projeto atual e evolução para ensino e transferência de conhecimento corporativo

Documento baseado na leitura do código do repositório (estado do commit `ea15713`, mais arquivos não versionados `Dockerfile` e `.ddev/`).

---

## 1. Visão geral do projeto hoje

### 1.1 Propósito
Aplicação local que permite **gravar ou enviar um áudio, transcrevê-lo em português** e, opcionalmente, **converter o texto em um "relato de problema de TI" estruturado** (JSON com relator, prioridade, origem, URL, status). O foco atual é o suporte de TI (`app/streamlit_app.py`: "Relato de Problema — TI"). Toda a inferência (Whisper e Ollama) roda localmente, o que é um diferencial importante para o uso corporativo.

### 1.2 Stack

| Camada | Tecnologia | Onde |
|---|---|---|
| Interface | Streamlit + `streamlit-audiorecorder` | `app/streamlit_app.py`, `app/components/report_form.py`, `app/state/session.py` |
| API | FastAPI + Uvicorn | `app/main.py` |
| Conversão de áudio | `pydub` (exige FFmpeg) | `core/audio/processor.py` |
| Transcrição (STT) | `faster-whisper` (padrão, modelo `medium`, CPU, int8); Vosk como fallback | `core/speech_to_text/whisper_engine.py`, `vosk_engine.py` |
| Pós-processamento | Regras de limpeza, correção de termos de TI, junção de segmentos curtos | `core/nlp/pipeline.py`, `core/nlp/utils.py` |
| LLM | Ollama local, modelo `llama3.2` | `core/ai_clients/local_client.py` |
| Configuração | `pydantic-settings` + `.env` | `config/settings.py`, `config/constants.py` |
| Persistência | Arquivos JSON em `data/reports/` | `services/report_service.py` |
| Execução | Scripts PowerShell/Bash, `Dockerfile` (Python 3.12-slim, sobe só a API), `.ddev/` (docker-compose com serviço Python) | `scripts/run_dev.ps1`, `scripts/run_dev.sh`, `Dockerfile`, `.ddev/docker-compose.python.yaml` |

### 1.3 Arquitetura (camadas)

```
Streamlit (app/streamlit_app.py)
        |  HTTP (requests, API_URL fixa http://localhost:8000)
        v
FastAPI (app/main.py)  -- /health  /process-audio  /structure-report
        |
        v
services/   PipelineService  TranscriptionService  AIService  ReportService
        |
        v
core/       audio/processor  speech_to_text/{base,whisper,vosk}  nlp/{pipeline,utils}
            ai_clients/{base,local}  report (dataclass)  orchestrator
```

Pontos de design positivos: há abstrações (`SpeechToTextEngine`, `BaseAIClient`) que permitem trocar motores, e o `Transcript`/`Segment` (`core/speech_to_text/base.py`) já carrega **timestamps e confiança por segmento**.

### 1.4 Fluxo de funcionamento

1. O usuário informa o nome na barra lateral e grava, envia um arquivo (wav, mp3, ogg, flac, m4a, mp4, webm) ou digita texto.
2. `POST /process-audio` recebe os bytes, grava um arquivo temporário e chama `PipelineService.run_from_bytes`.
3. `to_vosk_wav` valida o formato e o tamanho (limite de 500 MB) e converte para WAV mono, 16 kHz, 16 bits.
4. `TranscriptionService` escolhe o Whisper (ou Vosk, se `faster-whisper` não estiver instalado) e gera segmentos com início, fim e confiança. O Whisper usa `vad_filter=True` e idioma fixo `pt`.
5. `NLPPipeline` funde segmentos curtos, limpa o texto, corrige termos de TI, capitaliza e pontua.
6. A API devolve `transcription`, `duration` e `segments`. A interface mostra somente o texto, em área editável, para revisão.
7. `POST /structure-report` (exige Ollama com `llama3.2`) pede ao LLM um JSON com `relato`, `prioridade`, `origem` e `url`. O `AIService` valida os valores permitidos, cria o `Report` com status "Bruto" e o `ReportService` grava em `data/reports/AAAA-MM-DD_<id>.json`.
8. O usuário revisa o relato, clica em "Confirmar e Salvar" e o status passa a "Corrigido" (apenas em memória na sessão do Streamlit).

---

## 2. Limitações atuais

**Produto e funcionalidade**
- Domínio restrito a relatos de TI: o prompt (`_SYSTEM_STRUCTURE` em `services/ai_services.py`) e o modelo `Report` (`core/report.py`, campos prioridade/origem) são específicos de suporte.
- Só processa **um áudio curto por vez**, de forma síncrona (`asyncio.to_thread` na requisição HTTP). Reuniões ou treinamentos de horas bloqueariam a requisição e sofreriam timeout. Não há fila, progresso nem retomada.
- **Sem diarização**: não identifica quem fala.
- Os segmentos com timestamp existem na API, mas a interface os descarta; não há exportação para SRT/VTT (`srt` está em `requirements.txt` e há constantes `SRT_*` em `config/constants.py`, mas sem uso).
- Idioma fixo `pt` (`whisper_language`) e sem vocabulário customizado por empresa (a correção de termos em `core/nlp/utils.py` é por regras estáticas).
- Sem resumo, ata, capítulos, busca, perguntas e respostas ou quizzes. O LLM só faz uma chamada de estruturação.
- Persistência simples (arquivos JSON): sem banco, sem histórico da transcrição, sem relação entre áudio, transcrição e relato. O áudio original não é guardado e a transcrição bruta não é salva. O "Confirmar e Salvar" não regrava o arquivo (a edição fica só em sessão).
- Sem testes: `tests/unit`, `integration` e `e2e` têm apenas `.gitkeep`.

**Inconsistências e dívida técnica observadas**
- O prompt enviado ao LLM é `f"...\n\n{text}"` (literal `...`), e o `AIService` faz `json.loads` direto: qualquer resposta do LLM fora do JSON puro gera erro. Não há modo JSON/saída estruturada nem retentativas. A mensagem de erro cita "chave de IA no .env", embora o cliente seja só o Ollama.
- `config/settings.py` fala de um `FallbackClient` (Anthropic, Groq, OpenAI, Gemini) que **não existe**; só `LocalClient` está implementado, com o modelo `llama3.2` fixo em constante (o campo `local_ai_model` não é usado). Dependências como `anthropic`, `openai`, `google-genai` estão instaladas sem uso.
- `core/speech_to_text/whisper_engine.py` **desabilita a verificação SSL globalmente** (`ssl._create_default_https_context = ssl._create_unverified_context` e `CURL_CA_BUNDLE=""`) para contornar proxies corporativos. É um risco de segurança que deve virar configuração de CA corporativa.
- `app/main.py`: CORS com `allow_origins=["*"]`, **sem autenticação**, sem limite de requisições; `API_URL` fixa no front; `uvicorn` com host `0.0.0.0` no `Dockerfile`/`.ddev`.
- `frontend/app.py` e `frontend/utils.py` são um protótipo antigo (espera `ai_analysis` e `Vosk`, que a API atual não retorna). O `Dockerfile` copia o projeto inteiro e sobe só a API (sem FFmpeg, sem Streamlit, sem Ollama). O `.ddev/` é um template de PHP/DDEV com um serviço Python acoplado, o que não é um modelo de implantação corporativo.
- `core/orchestrator.py` não é usado pela API; a lógica fica espalhada entre `app/main.py` e os serviços. `requirements.txt` mistura dependências diretas com um `pip freeze` (por exemplo, `GitPython`, `pydeck`), e `.gitignore` ignora `*.env` e `data/`, o que é adequado.
- Detalhe de Whisper: a "confiança" é `avg_logprob` (negativa), não uma probabilidade, e o NLP de termos de TI não generaliza para outros domínios.

---

## 3. Roadmap de evolução para ensino e transferência de conhecimento

### 3.1 Visão de produto
Transformar a ferramenta, hoje uma "voz para relato de TI", em uma **plataforma de captura e reutilização de conhecimento**: gravação ou upload de reuniões, treinamentos e explicações de especialistas, que viram transcrição com falantes e tempos, resumo, ata, capítulos, base pesquisável (RAG) e material de aprendizagem (quiz, trilha). A decisão arquitetural central é preservar o ponto forte do projeto, que é **rodar 100% local/on-premise**, com dados sob controle da empresa.

### 3.2 Fase 1 — Curto prazo (0 a 2 meses): fundação e valor imediato

| # | Item | Descrição / base no código | Esforço | Riscos |
|---|---|---|---|---|
| 1.1 | Higiene e testes | Corrigir prompt `"..."`, saída JSON validada (esquema Pydantic, `format="json"` do Ollama, retentativas), remover SSL desabilitado, remover dependências não usadas, usar `local_ai_model` das settings, testes unitários em `core/nlp`, `core/audio`, `ReportService` | 1 a 2 semanas | Baixo |
| 1.2 | Transcrição como produto | Salvar áudio, transcrição bruta e metadados; exibir segmentos com timestamps; exportar TXT, SRT/VTT, DOCX/Markdown (usar `srt` e constantes já existentes) | 1 semana | Baixo |
| 1.3 | Processamento assíncrono | Fila de jobs (RQ/Celery ou `BackgroundTasks` + tabela de jobs), endpoint `POST /jobs` + `GET /jobs/{id}`, barra de progresso; suporte a arquivos longos (chunking, o limite hoje é 500 MB) | 2 semanas | Médio: tempo de CPU do Whisper `medium` (pode ser maior que a duração do áudio) |
| 1.4 | Resumo e ata | Novos prompts/esquemas: resumo executivo, decisões, ações com responsável e prazo, perguntas em aberto. Generalizar `Report` para "Documento de conhecimento" com tipo | 1 a 2 semanas | Médio: alucinação do LLM local; exigir revisão humana (já existe o fluxo "Bruto" para "Corrigido") |
| 1.5 | Vocabulário e idioma | Dicionário de termos por empresa/área (substitui regras fixas), `initial_prompt` do Whisper, seleção de idioma | 1 semana | Baixo |
| 1.6 | Empacotamento | `docker-compose` real (API + Streamlit + Ollama + volume de modelos, FFmpeg na imagem), remover o acoplamento ao DDEV/PHP | 1 semana | Baixo |

**Resultado da fase 1:** uma ferramenta confiável, que transforma uma reunião gravada em transcrição, ata e resumo revisáveis, ainda em instalação única.

### 3.3 Fase 2 — Médio prazo (2 a 6 meses): conhecimento reutilizável

| # | Item | Descrição | Esforço | Riscos |
|---|---|---|---|---|
| 2.1 | Diarização de falantes | `pyannote.audio` (já há campo `hf_token` em `settings`) ou `whisperx`; mapear falantes para pessoas/papéis | 2 a 3 semanas | Médio: necessita aceite de modelo no Hugging Face (offline depois), GPU recomendada |
| 2.2 | Capítulos e navegação | Segmentação por tópicos (LLM + embeddings), índice com timestamps e player sincronizado com a transcrição | 2 semanas | Médio |
| 2.3 | Base de conhecimento pesquisável (RAG) | Banco (PostgreSQL + pgvector ou Qdrant), embeddings locais (ex.: `bge-m3`, multilíngue), chunking por segmento/tópico, busca híbrida, chat com respostas **com citação do trecho e do minuto do áudio** | 4 a 6 semanas | Alto: qualidade da recuperação, custos de hardware, avaliação |
| 2.4 | Material de aprendizagem | Geração de quizzes (múltipla escolha, V/F, abertas), flashcards, glossário, resumo por nível; banco de questões com revisão do instrutor | 3 semanas | Médio: erros factuais; exigir aprovação do especialista |
| 2.5 | Trilhas de aprendizado | Agrupar conteúdos em trilhas com pré-requisitos, progresso e avaliação; exportar SCORM/xAPI para LMS | 4 semanas | Médio |
| 2.6 | Multilíngue | Detecção de idioma, tradução de transcrições e resumos (PT/EN/ES), legendas multilíngues | 2 semanas | Médio |
| 2.7 | Identidade e acesso | Login SSO (OIDC/Azure AD/Keycloak), papéis (autor, revisor, aprendiz, admin), espaços por equipe, CORS restrito, auditoria | 3 semanas | Médio |
| 2.8 | Frontend de produto | Migrar do Streamlit para um frontend dedicado (React/Next) se a adoção crescer; Streamlit serve para o MVP | 4 a 6 semanas | Médio |

### 3.4 Fase 3 — Longo prazo (6 a 18 meses): plataforma corporativa

| # | Item | Descrição | Esforço | Riscos |
|---|---|---|---|---|
| 3.1 | Integrações de captura | Teams (Graph API / gravações do SharePoint), Zoom (webhooks de gravação na nuvem), Google Meet; upload automático e reconhecimento de reuniões | 4 a 8 semanas por conector | Alto: permissões, consentimento, mudanças de API |
| 3.2 | Integrações de destino | Confluence/SharePoint/Notion (publicar atas e páginas), Jira/ServiceNow (criar chamados a partir de relatos: aproveita o modelo atual de relato de TI), Slack/Teams (bot de perguntas) | 3 a 5 semanas por integração | Médio |
| 3.3 | Transcrição ao vivo | Streaming (WebSocket + `whisper-streaming`/VAD), legendas em tempo real, notas ao vivo | 6 a 10 semanas | Alto: latência e GPU |
| 3.4 | Governança de conteúdo | Ciclo de vida (rascunho, revisado, publicado, obsoleto), responsável pelo conteúdo, revisão periódica, versões, detecção de duplicidade e conflito | 6 semanas | Médio |
| 3.5 | Segurança, LGPD e on-premise | Ver 3.6 | contínuo | Alto |
| 3.6 | Métricas e analytics | Painel de adoção, cobertura de conhecimento por área, lacunas (perguntas sem resposta no RAG), progresso e nota em trilhas, tempo economizado, qualidade (WER amostral, taxa de edição humana) | 4 semanas | Baixo |
| 3.7 | Avatar de especialista / "segundo cérebro" | Assistente que responde no estilo e no escopo de um especialista com base apenas em conteúdo aprovado e citado | 8 semanas+ | Alto: reputação e consentimento da pessoa |

### 3.5 Detalhamento transversal: segurança, LGPD e execução on-premise

- **Dados pessoais**: voz é dado pessoal e pode revelar dados sensíveis. Definir base legal (legítimo interesse ou consentimento), aviso e consentimento antes de gravar, finalidade explícita, política de retenção e exclusão (direito do titular) por gravação.
- **Privacidade por padrão**: manter Whisper e LLM locais (Ollama/vLLM). O código já aceita várias APIs em nuvem nas settings; se forem implementadas, devem ser **opcionais, desligadas por padrão e com anonimização** (mascarar CPF, e-mails, nomes) antes de qualquer envio externo.
- **Proteção técnica**: autenticação obrigatória, criptografia em repouso (volumes/objetos) e em trânsito (TLS no proxy reverso), segredos fora do repositório, trilha de auditoria de acessos, remoção do SSL desabilitado em favor de CA corporativa, CORS restrito, limite de tamanho e taxa, varredura de arquivos enviados.
- **Controle de acesso**: ACL por espaço/coleção, e **a busca RAG deve filtrar por permissão do usuário antes de recuperar**, para não vazar conteúdo restrito via respostas do chat.
- **Implantação**: contêineres (API, worker, frontend, banco, vetor, Ollama/vLLM), com GPU opcional; modo "air-gapped" com modelos pré-baixados (`models/whisper`, `models/vosk` já são diretórios configuráveis; `scripts/download_models.py` pode ser a base para um pacote offline). Checar licenças dos modelos (Whisper MIT; Llama 3.2 licença própria; pyannote exige aceite) com o jurídico.
- **Qualidade e responsabilidade**: todo conteúdo gerado por IA deve ficar marcado como "gerado, aguardando revisão" até a aprovação humana (generalização do status Bruto/Corrigido que já existe), sempre com link para o trecho original.

### 3.6 Priorização resumida

```
Agora      : 1.1 higiene/testes -> 1.2 exportação -> 1.3 fila/arquivos longos -> 1.4 resumo/ata
Depois     : 2.1 diarização -> 2.7 SSO/papéis -> 2.3 RAG com citação -> 2.4 quiz/trilha
Mais tarde : 3.1/3.2 integrações -> 3.6 métricas -> 3.3 tempo real
```

Critério: entregar primeiro o que dá valor com o menor risco e destrava as etapas seguintes (transcrição confiável e assíncrona e metadados persistidos são pré-requisito do RAG; SSO e papéis são pré-requisito de qualquer base compartilhada).

### 3.7 Riscos principais do programa

| Risco | Mitigação |
|---|---|
| Desempenho do Whisper `medium` em CPU | Fila, modelo `small`/`distil` para rascunho, GPU, `faster-whisper` com batch |
| Alucinação ou erro do LLM local | Revisão humana obrigatória, citações com timestamp, avaliação com conjunto de teste interno, modelos maiores (Qwen/Llama 70B) onde houver GPU |
| Adoção baixa ("mais uma ferramenta") | Integrar onde o trabalho já ocorre (Teams, Confluence), piloto com 1 ou 2 equipes |
| Questões legais (consentimento, LGPD, sindicato/RH) | DPO envolvido desde o início, política de gravação clara |
| Qualidade de áudio e jargão interno | Vocabulário por empresa, pré-processamento, orientação de gravação |
| Escopo e dívida técnica | Fase 1 com testes e refatoração antes de novos recursos |

---

## 4. Casos de uso corporativos concretos

1. **Onboarding**: reuniões de apresentação de sistemas, "walk-throughs" de código e processos viram uma trilha de aprendizado com capítulos, glossário, quiz de verificação e um chat RAG que responde "como solicito acesso ao ambiente X?" citando o vídeo e o minuto. Métrica: tempo até a primeira entrega do novo colaborador.
2. **Offboarding e saída de especialistas**: sessões de entrevista guiada (roteiro de perguntas gerado pelo sistema a partir de lacunas na base) com o especialista que está saindo. O resultado é uma base com decisões, "porquês" históricos, armadilhas e procedimentos. O LLM identifica lacunas ("não foi explicado como funciona o fechamento mensal") e gera perguntas de acompanhamento. O especialista valida o conteúdo antes da publicação.
3. **Treinamentos e capacitações**: transcrição com legendas multilíngues, resumo por aula, material complementar, quiz com banco de questões aprovado pelo instrutor, exportação para o LMS e relatório de quem concluiu. Reaproveita treinamentos presenciais gravados.
4. **Suporte e operações (evolução do caso atual)**: o técnico narra o atendimento por voz e o sistema gera o relato estruturado (já existe), um artigo de base de conhecimento (problema, causa, solução) e, com integração, um chamado no Jira/ServiceNow. Com o tempo, o RAG sugere soluções de incidentes anteriores. Métricas: reincidência e tempo de resolução.
5. **Reuniões de decisão e arquitetura**: atas com decisões e ações com responsável, vinculadas ao trecho do áudio, formando um registro de decisões pesquisável (ADR falado).
6. **Acessibilidade e inclusão**: legendas e transcrições para pessoas com deficiência auditiva ou falantes não nativos, com tradução.

---

## 5. Conclusão e próximo passo recomendado

O projeto tem uma base pequena (cerca de 1.500 linhas) e bem separada em camadas, com dois ativos estratégicos: **processamento local (Whisper + Ollama), compatível com exigências de privacidade corporativa**, e **segmentos com timestamps e confiança** já disponíveis. Por outro lado, ele ainda é um protótipo de caso único (relato de TI), síncrono, sem autenticação, sem testes, com dívida de segurança (SSL desabilitado, CORS aberto) e com código previsto, mas não implementado (fallback de IA em nuvem).

**Recomendação de próximo passo (2 a 3 semanas), em ordem:**
1. Fazer a higiene da Fase 1.1 (prompt, JSON validado, SSL, dependências, testes mínimos) e empacotar com `docker-compose` real (1.6).
2. Persistir áudio, transcrição com segmentos e metadados e exportar SRT/TXT (1.2); processar em segundo plano (1.3).
3. Generalizar o `Report` para "documento de conhecimento" e implementar **resumo + ata com revisão humana** (1.4).
4. Rodar um **piloto com uma equipe** (por exemplo, onboarding ou saída de um especialista), medindo tempo economizado e taxa de edição humana, antes de investir em diarização, RAG e integrações (Fases 2 e 3).

Esse caminho entrega valor visível rapidamente, reduz risco técnico e legal, e gera os dados reais necessários para decidir o investimento em RAG, trilhas e integrações.

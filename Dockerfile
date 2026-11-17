# 1. Define a imagem base leve do Python 3.12
FROM python:3.12-slim

# 2. Define o diretório de trabalho dentro do contêiner
WORKDIR /app

# 3. Copia o arquivo de dependências primeiro (aproveita o cache do Docker)
COPY requirements.txt .

# 4. Instala as dependências do projeto sem cache do pip para economizar espaço
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copia o restante do código da aplicação para o contêiner
COPY . .

# 6. Define o comando padrão para rodar a sua aplicação Python
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

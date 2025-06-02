# Etapa 1: Build da aplicação
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Etapa 2: Servir arquivos estáticos com http-server
FROM node:18-alpine

WORKDIR /app

# Instala um servidor estático leve para servir o dist/
RUN npm install -g http-server

# Copia os arquivos do build
COPY --from=build /app/dist .

# Expõe a porta do servidor
EXPOSE 8080

# Comando para rodar o servidor
CMD ["http-server", ".", "-p", "8080"]

# Etapa 1: Build da aplicação
FROM node:18-alpine AS build

WORKDIR /app

# Cria um arquivo .env com a URL do backend
RUN echo "VITE_API_URL=http://localhost:3000" > .env

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Etapa 2: Servir com Nginx
FROM nginx:alpine

# Remove a configuração padrão do nginx
RUN rm -rf /etc/nginx/conf.d/*

# Adiciona nossa configuração do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia os arquivos do build
COPY --from=build /app/dist /usr/share/nginx/html

# Expõe a porta do servidor
EXPOSE 80

# Comando para iniciar o nginx
CMD ["nginx", "-g", "daemon off;"]

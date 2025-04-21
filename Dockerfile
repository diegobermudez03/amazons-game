FROM cirrusci/flutter:latest AS builder
WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web

FROM nginx:alpine

COPY --from=builder /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

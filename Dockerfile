FROM oven/bun:0.5.9
WORKDIR /app

ENTRYPOINT ["bun" , "start"]

COPY package.json package.json
COPY bun.lockb bun.lockb

RUN bun install
COPY . .

// @ts-ignore
import swaggerJsdoc from 'swagger-jsdoc';
import pkg from '../package.json';

const name = pkg.name || 'example-project';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: name
        .split('-')
        .map((w) => w.at(0)?.toUpperCase() + w.substring(1))
        .join(' '),
      version: pkg.version || '1.0.0'
    },
    servers: [
      {
        url: 'http://localhost:3000/api',
        description: 'Local dev server'
      },
      {
        url: 'https://something.google.com/api',
        description: 'Production'
      }
    ]
  },
  apis: ['./src/**/*.ts']
};

const openapiSpecification = swaggerJsdoc(options);

Bun.write(
  './src/swagger.json',
  JSON.stringify(openapiSpecification, undefined, 2)
);

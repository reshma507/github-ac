export default ({ env }) => {
  const client = env('DATABASE_CLIENT', 'sqlite');

  const connections = {
    sqlite: {
      connection: {
        filename: env('DATABASE_FILENAME', '/data/data.db'),
      },
      useNullAsDefault: true,
    },

    postgres: {
      connection: {
        host: env('DATABASE_HOST'),
        port: env.int('DATABASE_PORT', 5432),
        database: env('DATABASE_NAME'),
        user: env('DATABASE_USERNAME'),
        password: env('DATABASE_PASSWORD'),
        ssl: env.bool('DATABASE_SSL', false),
      },
    },
  };

  return {
    connection: {
      client,
      ...connections[client],
    },
  };
};

// export default ({ env }) => ({
//   connection: {
//     client: "postgres",
//     connection: {
//       host: env("DATABASE_HOST", "127.0.0.1"),
//       port: env.int("DATABASE_PORT", 5432),
//       database: env("DATABASE_NAME", "strapi_db"),
//       user: env("DATABASE_USERNAME", "strapi_user"),
//       password: env("DATABASE_PASSWORD", "strapi_pass"),
//       ssl: env.bool("DATABASE_SSL", false)
//     },
//     debug: false,
//   },
// });
// export default ({ env }) => ({
//   connection: {
//     client: 'sqlite',
//     connection: {
//       filename: env('DATABASE_FILENAME', '/data/data.db'),
//     },
//     useNullAsDefault: true,
//   },
// });

// export default ({ env }) => ({
//   connection: {
//     client: 'postgres',
//     connection: {
//       host: env('DATABASE_HOST', 'strapi-postgres'),
//       port: env.int('DATABASE_PORT', 5432),
//       database: env('DATABASE_NAME', 'strapi_db'),
//       user: env('DATABASE_USERNAME', 'strapi'),
//       password: env('DATABASE_PASSWORD', 'strapi123'),
//       ssl: false,
//     },
//     acquireConnectionTimeout: 60000,
//   },
// });
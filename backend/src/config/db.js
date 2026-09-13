const { Pool } = require("pg");

const pool = new Pool({
  host: "localhost",
  port: 5432,
  database: "task_management",
  user: "taskuser",
  password: "taskpassword",
});

module.exports = pool;
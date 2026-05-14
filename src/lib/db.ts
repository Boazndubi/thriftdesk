import { Pool } from 'pg'

// Connection to your Docker PostgreSQL
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'postgres',
  user: 'postgres',
  password: 'your-super-secret-password',
})

export default pool

import pool from '@/lib/db'

export default async function TestPage() {
  // Test database connection
  const result = await pool.query('SELECT NOW() as time')
  const dbTime = result.rows[0].time

  // Convert Date to string for React
  const timeString = dbTime instanceof Date 
    ? dbTime.toLocaleString() 
    : String(dbTime)

  // Count tables
  const tables = await pool.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
  `)

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">ThriftDesk Database Test</h1>
      
      <div className="bg-green-100 p-4 rounded mb-4">
        <p className="text-green-800">
          ? Database connected! Server time: {timeString}
        </p>
      </div>

      <h2 className="text-xl font-semibold mb-2">Your Tables:</h2>
      <ul className="list-disc pl-5">
        {tables.rows.map((row) => (
          <li key={row.table_name}>{row.table_name}</li>
        ))}
      </ul>
    </div>
  )
}

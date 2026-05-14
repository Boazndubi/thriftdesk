export const metadata = {
  title: 'ThriftDesk',
  description: 'Mtumba marketplace for TikTok sellers',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}

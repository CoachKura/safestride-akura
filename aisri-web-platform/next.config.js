/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ["bdisppaxbvygsspcuymb.supabase.co"],
  },
  async redirects() {
    return [
      {
        source: "/",
        destination: "/login",
        permanent: false,
        has: [
          {
            type: "cookie",
            key: "sb-access-token",
          },
        ],
      },
    ];
  },
};

module.exports = nextConfig;

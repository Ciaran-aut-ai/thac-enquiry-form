# THAC Projects Monorepo

A unified repository containing all THAC (The Housing Authority of Canada) projects.

## Project Structure

```
thac-enquiry-form/
├── admin/           # THAC Admin Dashboard
│   ├── .github/     # GitHub Actions workflows
│   ├── css/         # Stylesheets
│   ├── js/          # JavaScript files
│   └── supabase/    # Supabase functions
│
└── enquiry-form/    # THAC Enquiry Form
    └── index.html   # Main form page
```

## Projects

### Admin Dashboard (`/admin`)
The THAC admin dashboard for managing clients, jobs, surveyors, and enquiries.

**Features:**
- Client management
- Job tracking
- Surveyor management
- Enquiry tracking
- Real-time updates via Supabase

**Key Files:**
- `dashboard.html` - Main dashboard
- `clients.html` - Client management
- `jobs.html` - Job management
- `surveyors.html` - Surveyor management
- `enquiries.html` - Enquiry tracking

### Enquiry Form (`/enquiry-form`)
Public-facing enquiry form for submitting THAC requests.

**Files:**
- `index.html` - Main enquiry form

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Ciaran-aut-ai/thac-enquiry-form.git
   cd thac-enquiry-form
   ```

2. Install dependencies (if needed):
   - Admin dashboard requires Supabase configuration
   - Refer to individual project documentation

## Environment Configuration

### Supabase
Create a `.env` file in the project root with your Supabase credentials:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_anon_key
```

## Development

Each project can be developed independently within this monorepo structure.

### Admin Dashboard
Navigate to `admin/` and check the local documentation for build/run instructions.

### Enquiry Form
Navigate to `enquiry-form/` and open `index.html` in a browser.

## Deployment

GitHub Actions workflows are configured in `.github/workflows/` for automated deployments.

## Contributing

1. Create a feature branch
2. Make your changes
3. Commit with descriptive messages
4. Push and create a pull request

## License

[Add your license information here]

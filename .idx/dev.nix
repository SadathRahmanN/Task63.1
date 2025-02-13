# .idx/dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";
  
  packages = [
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
    pkgs.postgresql  # For database support
    pkgs.libffi  # Required for some Python packages
    pkgs.openssl  # SSL development support
  ];

  idx = {
    extensions = [ 
      "ms-python.python"
      "ms-python.vscode-pylance"
    ];
    
    workspace = {
      onCreate = {
        setup-project = ''
          # Create virtual environment inside project directory
          python -m venv tourist_project/.venv
          source tourist_project/.venv/bin/activate

          # Install base dependencies
          pip install --upgrade pip wheel

          # Install requirements or create default
          if [ -f "tourist_project/requirements.txt" ]; then
            echo "Installing project dependencies..."
            pip install -r tourist_project/requirements.txt
          else
            echo "Creating default requirements.txt..."
            cat > tourist_project/requirements.txt << EOF
            Django>=5.0
            django-crispy-forms
            django-crispy-bootstrap5
            djangorestframework
            psycopg2-binary
            EOF
            pip install -r tourist_project/requirements.txt
          fi

          # Initialize Django project structure
          if [ ! -f "tourist_project/manage.py" ]; then
            echo "Initializing Django project..."
            cd tourist_project
            django-admin startproject tourist_project .
            
            # Create default settings
            cat > tourist_project/settings.py << EOF
            import os
            from pathlib import Path

            BASE_DIR = Path(__file__).resolve().parent.parent
            SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'django-insecure-default-key')
            DEBUG = True
            ALLOWED_HOSTS = ['*']

            INSTALLED_APPS = [
                'django.contrib.admin',
                'django.contrib.auth',
                'django.contrib.contenttypes',
                'django.contrib.sessions',
                'django.contrib.messages',
                'django.contrib.staticfiles',
                'crispy_forms',
                'crispy_bootstrap5',
                'rest_framework',
                'destinations',
            ]

            MIDDLEWARE = [
                'django.middleware.security.SecurityMiddleware',
                'django.contrib.sessions.middleware.SessionMiddleware',
                'django.middleware.common.CommonMiddleware',
                'django.middleware.csrf.CsrfViewMiddleware',
                'django.contrib.auth.middleware.AuthenticationMiddleware',
                'django.contrib.messages.middleware.MessageMiddleware',
                'django.middleware.clickjacking.XFrameOptionsMiddleware',
            ]

            ROOT_URLCONF = 'tourist_project.urls'
            TEMPLATES = [...]  # Template configuration
            WSGI_APPLICATION = 'tourist_project.wsgi.application'

            DATABASES = {
                'default': {
                    'ENGINE': 'django.db.backends.sqlite3',
                    'NAME': BASE_DIR / 'db.sqlite3',
                }
            }

            STATIC_URL = 'static/'
            STATIC_ROOT = BASE_DIR / 'staticfiles'
            DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
            CRISPY_ALLOWED_TEMPLATE_PACKS = "bootstrap5"
            CRISPY_TEMPLATE_PACK = "bootstrap5"
            EOF
            
            cd ..
          fi
        '';

        default.openFiles = [
          "tourist_project/manage.py"
          "tourist_project/tourist_project/settings.py"
        ];
      };
    };

    previews = {
      enable = true;
      previews = {
        web = {
          command = [
            "bash" "-c"
            ''
              # Activate virtual environment
              source tourist_project/.venv/bin/activate
              
              # Set environment variables
              export PYTHONPATH="$PYTHONPATH:$PWD/tourist_project"
              export DJANGO_SETTINGS_MODULE="tourist_project.settings"
              
              # Database migrations
              python tourist_project/manage.py migrate
              
              # Create superuser if none exists
              if [ -z "$(python tourist_project/manage.py shell -c 'from django.contrib.auth import get_user_model; print(get_user_model().objects.exists())')" ]; then
                echo "Creating default superuser..."
                python tourist_project/manage.py createsuperuser --noinput --username admin --email admin@example.com
              fi
              
              # Start development server
              python tourist_project/manage.py runserver 0.0.0.0:$PORT
            ''
          ];
          env = {
            PORT = "8000";
            DJANGO_SECRET_KEY = "your-secret-key-here";
          };
          manager = "web";
        };
      };
    };
  };

  # Add shell hooks for environment activation
  env = {
    VIRTUAL_ENV = ".venv";
    PATH = "${pkgs.lib.makeBinPath [ 
      "${pkgs.python3}/bin"
      "${pkgs.nodejs}/bin"
    ]}:$PATH";
  };

  shell = {
    hooks = {
          activate = ''
            # Automatically activate virtual environment
            if [ -d ".venv" ]; then
              source /.venv/bin/activate
            fi
          '';
        };
  };
}
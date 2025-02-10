# .idx/dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";
  
  packages = [
    pkgs.python3
    pkgs.python3Packages.pip
    pkgs.python3Packages.virtualenv
  ];

  idx = {
    extensions = [ "ms-python.python" ];
    
    workspace = {
      onCreate = {
        setup-project = ''
          # Create virtual environment in the root directory
          python -m venv .venv
          source .venv/bin/activate
          
          # Install dependencies from requirements.txt
          if [ -f "tourist_project/requirements.txt" ]; then
            echo "Installing dependencies from requirements.txt"
            pip install -r tourist_project/requirements.txt
          else
            echo "Creating default requirements.txt"
            echo "Django>=5.0" > tourist_project/requirements.txt
            pip install -r tourist_project/requirements.txt
          fi

          # Verify inner project structure
          if [ ! -f "tourist_project/tourist_project/__init__.py" ]; then
            echo "Creating inner project structure"
            cd tourist_project
            django-admin startproject tourist_project .
            cd ..
          fi
        '';
        
        default.openFiles = [
          "../tourist_project/manage.py"
          "../tourist_project/tourist_project/settings.py"
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
              # Activate the virtual environment
              source .venv/bin/activate
              
              # Set the Python path and environment variables
              export PYTHONPATH="$PYTHONPATH:$PWD/tourist_project"
              export DJANGO_SETTINGS_MODULE="tourist_project.tourist_project.settings"
              
              # Start the Django development server
              python tourist_project/manage.py runserver 0.0.0.0:$PORT --noreload
            ''
          ];
          env = {
            PORT = "$PORT";
          };
          manager = "web";
        };
      };
    };
  };
}
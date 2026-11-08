{
  flake.modules.nixos.ollama =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      domain = config.my.network.domain;
      # RTX 4090 (Ada): avoid compiling runners for unrelated GPU generations.
      ollama = pkgs.ollama-cuda.override { cudaArches = [ "sm_89" ]; };
    in
    {
      config = lib.mkMerge [
        {
          my.services.ollama = {
            # Open WebUI in front of Ollama.
            port = 3000;
            publicName = "ai";
          };
        }
        (lib.mkIf config.my.services.ollama.enable {
          # The desktop loads NVIDIA in the initrd; ensure CUDA's UVM module is also
          # loaded in stage 2 before the sandboxed Ollama service starts.
          boot.kernelModules = [ "nvidia_uvm" ];

          services.ollama = {
            enable = true;
            package = ollama;
            host = "127.0.0.1";
            loadModels = [ "huihui_ai/qwen3.5-abliterated:27b" ];
            environmentVariables = {
              OLLAMA_CONTEXT_LENGTH = "32768";
              OLLAMA_FLASH_ATTENTION = "1";
              OLLAMA_KV_CACHE_TYPE = "q8_0";
              OLLAMA_NUM_PARALLEL = "1";
              OLLAMA_MAX_LOADED_MODELS = "1";
            };
          };

          environment.systemPackages = [ ollama ];

          # fpdf2 2.8.9: one PDF fixture hash differs with the pinned image stack.
          # Keep the remaining upstream checks enabled (1780 passed before this override).
          nixpkgs.overlays = [
            (_final: prev: {
              pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
                (_pythonFinal: pythonPrev: {
                  fpdf2 = pythonPrev.fpdf2.overridePythonAttrs (old: {
                    disabledTests = (old.disabledTests or [ ]) ++ [
                      "test_image_with_explicit_dimensions"
                    ];
                  });
                })
              ];
            })
          ];

          services.open-webui = {
            enable = true;
            host = "127.0.0.1";
            port = 3000;
            environment = {
              WEBUI_URL = "https://ai.${domain}";
              OLLAMA_BASE_URL = "http://127.0.0.1:11434";
              DEFAULT_MODELS = "huihui_ai/qwen3.5-abliterated:27b";
              ENABLE_WEB_SEARCH = "True";
              WEB_SEARCH_ENGINE = "searxng";
              SEARXNG_QUERY_URL = "http://127.0.0.1:8888/search?q=<query>";
              WEB_SEARCH_RESULT_COUNT = "5";
              WEB_SEARCH_CONCURRENT_REQUESTS = "2";
              WEB_LOADER_CONCURRENT_REQUESTS = "2";
              # Put retrieved pages directly in context; avoid a second GPU model.
              BYPASS_WEB_SEARCH_EMBEDDING_AND_RETRIEVAL = "True";
              RAG_EMBEDDING_MODEL = "";
              RAG_EMBEDDING_MODEL_AUTO_UPDATE = "False";
              SCARF_NO_ANALYTICS = "True";
              DO_NOT_TRACK = "True";
              ANONYMIZED_TELEMETRY = "False";
            };
          };

          services.searx = {
            enable = true;
            environmentFile = "/var/lib/searxng-secret/environment";
            settings = {
              # These default engines returned CAPTCHAs/rate limits on this connection;
              # Bing was verified to return live results without an API key.
              use_default_settings.engines.keep_only = [ "bing" ];
              engines = [
                {
                  name = "bing";
                  disabled = false;
                }
              ];
              server = {
                bind_address = "127.0.0.1";
                port = 8888;
                secret_key = "$SEARX_SECRET_KEY";
                limiter = false;
              };
              search = {
                formats = [
                  "html"
                  "json"
                ];
                safe_search = 0;
              };
            };
          };

          # Generate the local service secret on the host, outside Git and the store.
          systemd.services.searxng-secret = {
            before = [ "searx-init.service" ];
            requiredBy = [ "searx-init.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StateDirectory = "searxng-secret";
              StateDirectoryMode = "0700";
              UMask = "0077";
            };
            script = ''
              if [ ! -s /var/lib/searxng-secret/environment ]; then
                printf 'SEARX_SECRET_KEY=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 32)" \
                  > /var/lib/searxng-secret/environment
              fi
            '';
          };
        })
      ];
    };
}

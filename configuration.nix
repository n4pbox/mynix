# ============================================================================
#  configuration.nix — Desktop Nvidia | Gaming + Dev | Flatpak | SRCDS
# ============================================================================
#
#  COMO USAR:
#    1. Copie este arquivo para /etc/nixos/configuration.nix
#       (faça backup do original antes: sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.bak)
#    2. Ajuste a seção "1. SISTEMA BASE" (hostname, timezone, usuário).
#    3. Rode: sudo nixos-rebuild switch
#
#  ESTRUTURA (use Ctrl+F / busca pelos títulos numerados):
#    1. SISTEMA BASE        — boot, hostname, timezone, locale
#    2. REDE                — NetworkManager, firewall
#    3. NVIDIA               — driver proprietário, OpenGL, Vulkan
#    4. DESKTOP / DE         — KDE Plasma (troque pra Hyprland/i3 aqui)
#    5. ÁUDIO                — PipeWire
#    6. USUÁRIO              — sua conta, grupos
#    7. PACOTES DO SISTEMA   — ferramentas base sempre instaladas
#    8. GAMING               — Steam, Proton, GameMode, MangoHud
#    9. DESENVOLVIMENTO      — linguagens, editores, Docker
#   10. FLATPAK              — habilitar + Flathub
#   11. SERVIDOR SRCDS       — steamcmd, firewall, systemd service simples
#   12. EXTRAS / MANUTENÇÃO  — garbage collection, optimise, flags do sistema
#
#  DICA: cada seção é independente. Pra desligar algo, comente o bloco
#  inteiro (Ctrl+/ no editor) ou apague — nada depende de ordem aqui.
# ============================================================================

{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix # gerado automaticamente pelo instalador, não mexa
  ];

  # ==========================================================================
  # 1. SISTEMA BASE
  # ==========================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel mais recente: melhor suporte a hardware novo (GPU, periféricos).
  # Se quiser mais estabilidade em vez de pacotes mais novos, troque para
  # pkgs.linuxPackages (sem o "_latest").
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # <-- TROQUE AQUI

  time.timeZone = "America/Sao_Paulo"; # <-- ajuste se necessário

  i18n.defaultLocale = "en_US.UTF-8";

  #LOCALES OPCIONAIS!

  #i18n.extraLocaleSettings = {
    #LC_ADDRESS = "pt_BR.UTF-8";
    #LC_IDENTIFICATION = "pt_BR.UTF-8";
    #LC_MEASUREMENT = "pt_BR.UTF-8";
    #LC_MONETARY = "pt_BR.UTF-8";
    #LC_NAME = "pt_BR.UTF-8";
    #LC_NUMERIC = "pt_BR.UTF-8";
    #LC_PAPER = "pt_BR.UTF-8";
    #LC_TELEPHONE = "pt_BR.UTF-8";
    #LC_TIME = "pt_BR.UTF-8";
  #};

  console.keyMap = "br-abnt2"; # troque para "us" se seu teclado for ABNT-less

  # Permite instalar pacotes não-livres (driver Nvidia, Steam, etc).
  nixpkgs.config.allowUnfree = true;

  # ==========================================================================
  # 2. REDE
  # ==========================================================================

  networking.networkmanager.enable = true;

  # Firewall ligado por padrão. Portas específicas (ex: SRCDS) são abertas
  # na seção 11 — o Nix mescla automaticamente as duas declarações de
  # "networking.firewall", então não há conflito, só separação por contexto.
  networking.firewall.enable = true;

  # ==========================================================================
  # 3. NVIDIA — driver proprietário
  # ==========================================================================

  # Habilita OpenGL/Vulkan no sistema (necessário para qualquer GPU).
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # essencial pra rodar jogos 32-bit via Steam/Proton
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Driver proprietário "stable" (recomendado). Existe também ".beta" se
    # quiser features mais novas, mas menos testadas.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting é necessário para Wayland e melhora o boot (sem tearing
    # na tela de boot). Mantenha true sempre.
    modesetting.enable = true;

    # Desktop com APENAS Nvidia (sem GPU híbrida) -> "open" pode ficar false,
    # pois o driver proprietário "kernel module" closed-source funciona bem
    # em placas Turing+ (GTX 16xx / RTX 20xx pra cima). Se você tiver uma RTX
    # série 20 ou mais nova e quiser o módulo kernel open-source da própria
    # Nvidia (mais novo, mantido por eles), troque para `true`.
    open = false;

    # Ativa o utilitário gráfico "nvidia-settings".
    nvidiaSettings = true;

    # Power management: geralmente não precisa em desktop (isso é mais
    # relevante para laptops com suspend/resume). Deixe false.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };

  # ==========================================================================
  # 4. DESKTOP / DE
  # ==========================================================================
  # Por padrão está configurado KDE PLASMA (Wayland), como você pediu.
  # Pra trocar no futuro pra Hyprland ou i3, veja os blocos comentados logo
  # abaixo: é só comentar o bloco do KDE e descomentar o que você quiser.
  # Não precisa mexer em mais nada — Nvidia, áudio, etc já funcionam com
  # qualquer um dos três.

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # --- OPÇÃO ALTERNATIVA: Hyprland -------------------------------------
  # Para trocar: comente o bloco do KDE acima e descomente abaixo.
  #
  # programs.hyprland.enable = true;
  # services.displayManager.sddm.enable = true; # ou greetd, à sua escolha
  #
  # # Hyprland precisa dessas variáveis de ambiente pra rodar bem com Nvidia:
  # environment.sessionVariables = {
  #   LIBVA_DRIVER_NAME = "nvidia";
  #   XDG_SESSION_TYPE = "wayland";
  #   GBM_BACKEND = "nvidia-drm";
  #   __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  #   WLR_NO_HARDWARE_CURSORS = "1";
  # };
  # -----------------------------------------------------------------------

  # --- OPÇÃO ALTERNATIVA: i3wm (X11) -------------------------------------
  # Para trocar: comente o bloco do KDE acima e descomente abaixo.
  #
  # services.xserver.enable = true;
  # services.xserver.windowManager.i3.enable = true;
  # services.displayManager.lightdm.enable = true;
  # -----------------------------------------------------------------------

  # Teclado também no ambiente gráfico (X11/XWayland usam isso).
  services.xserver.xkb.layout = "br";

  # ==========================================================================
  # 5. ÁUDIO — PipeWire (padrão moderno, substitui PulseAudio/JACK)
  # ==========================================================================

  services.pulseaudio.enable = false; # desabilita PulseAudio, usamos PipeWire
  security.rtkit.enable = true; # necessário pro PipeWire

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # áudio de jogos/apps 32-bit
    pulse.enable = true; # compatibilidade com apps que esperam PulseAudio
    jack.enable = true; # compatibilidade com apps de áudio profissional
  };

  # ==========================================================================
  # 6. USUÁRIO
  # ==========================================================================

  users.users.nap = { # <-- TROQUE "SEU_USUARIO" pelo seu nome de usuário
    isNormalUser = true;
    description = "nap";
    extraGroups = [
      "wheel" # permite usar sudo
      "networkmanager"
      "video"
      "audio"
      "docker" # necessário para usar Docker sem sudo (seção 9)
    ];
    shell = pkgs.zsh; # troque para pkgs.bash se preferir
  };

  programs.zsh.enable = true; # precisa estar habilitado se usar zsh acima

  # ==========================================================================
  # 7. PACOTES DO SISTEMA
  # ==========================================================================
  # Lista ÚNICA de pacotes, dividida em sub-blocos só por organização visual.
  # Pra remover algo, basta apagar a linha. Pra adicionar, basta criar uma
  # linha nova dentro do grupo que fizer mais sentido (ou criar um grupo novo).

  environment.systemPackages = with pkgs; [
    # --- essenciais de sistema ---
    wget
    curl
    git
    htop
    btop
    tree
    unzip
    p7zip
    file
    killall
    pciutils # lspci — útil pra debug de GPU/hardware
    usbutils # lsusb

    # --- ferramentas de Nvidia/GPU ---
    nvtopPackages.nvidia # monitor de uso da GPU, tipo htop

    # --- terminal ---
    kitty # terminal rápido, funciona bem com Wayland e Nvidia
    pkgs.fastfetch

    # --- gaming (seção 8) ---
    mangohud # overlay de FPS/temperatura/uso de GPU nos jogos
    protonup-qt # gerenciador gráfico de versões do Proton-GE
    lutris # launcher pra jogos fora da Steam (Epic, GOG, emuladores, etc)
    heroic # launcher pra Epic Games / GOG nativo no Linux
    wineWow64Packages.stable # Wine, caso precise rodar algo fora do Steam
    winetricks
    discord # comunicação enquanto joga

    # --- desenvolvimento (seção 9) ---
    vscode
    neovim
    python3
    nodejs_22
    go
    rustup # gerencia toolchains do Rust (rustc, cargo, etc)
    gcc
    gnumake
    cmake
    pkg-config
    jq # manipular JSON no terminal
    ripgrep # grep rápido
    fd # find rápido
    lazygit # interface TUI pro git
    postman

    # --- servidor SRCDS (seção 11) ---
    steamcmd
    # ---- Privacidade e afins ------
    pkgs.signal-desktop
    pkgs.kdePackages.kleopatra
    pkgs.i2p
    pkgs.tor-browser
    pkgs.proton-vpn
    #browsers
    pkgs.brave

  ];

  # Fontes (importante pra jogos/dev que usam ícones, ligatures, etc).
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
  ];

  # ==========================================================================
  # 8. GAMING
  # ==========================================================================

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # abre portas pro Steam Remote Play
    dedicatedServer.openFirewall = true; # abre portas pra servidores Steam (úteis p/ SRCDS também)
    gamescopeSession.enable = true; # permite rodar jogos via Gamescope (modo "consola")
  };

  # GameMode: otimiza performance da CPU/GPU automaticamente quando um jogo
  # está rodando (governor de CPU, prioridade de processo, etc).
  programs.gamemode.enable = true;

  # Os pacotes de gaming (MangoHud, Lutris, Heroic, Wine, Discord...) ficam
  # todos juntos na lista única da seção 7, no bloco "--- gaming ---".

  #Binary RUNNING - CRUTIAL
  programs.nix-ld.enable = true;

  # ==========================================================================
  # 9. DESENVOLVIMENTO
  # ==========================================================================
  # Os pacotes de dev (VSCode, Neovim, linguagens, toolchains...) ficam
  # todos juntos na lista única da seção 7, no bloco "--- desenvolvimento ---".

  # Docker — conforme você pediu.
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  # Lembrete: seu usuário já está no grupo "docker" lá na seção 6, então
  # não precisa de sudo pra rodar comandos docker depois do rebuild + reboot.

  # ==========================================================================
  # 10. FLATPAK
  # ==========================================================================

  services.flatpak.enable = true;

  # Adiciona o Flathub automaticamente como repositório (equivalente a rodar
  # "flatpak remote-add flathub https://flathub.org/repo/flathub.flatpakrepo"
  # manualmente, mas já fica garantido todo rebuild).
  systemd.services.flatpak-add-flathub-repo = {
    description = "Adiciona o repositório Flathub";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
    serviceConfig.Type = "oneshot";
  };

  # Dica: depois do rebuild, instale apps com:
  #   flatpak install flathub com.exemplo.App

  # ==========================================================================
  # 11. SERVIDOR SRCDS (Source Dedicated Server — CS:GO/CS2, TF2, GMod, etc)
  # ==========================================================================
  #
  # Simples: o servidor roda com o seu próprio usuário, sem usuário dedicado
  # nem sandboxing. Os arquivos ficam em /srv/srcds e você mexe neles
  # normalmente, sem precisar de "sudo -iu" pra nada.
  #
  # Pra ATIVAR um jogo: troque "enable = false" pra "true" no bloco
  # correspondente abaixo e ajuste a porta se precisar.

  # SteamCMD (na lista única da seção 7) é a ferramenta oficial da Valve
  # pra baixar/atualizar servidores.

  # --- Portas padrão de jogos baseados em Source -------------------------
  # Descomente as portas dos jogos que você realmente vai hospedar.
  networking.firewall = {
    allowedUDPPorts = [
       27015 # CS2 / CS:GO / TF2 / GMod (porta padrão de jogo)
       27020 # voz STV / SourceTV
    ];
    allowedTCPPorts = [
       27015 # RCON / consulta de servidor
    ];
  };

  # --- Exemplo de serviço systemd pra rodar um servidor SRCDS -------------
  # Isso transforma seu servidor em um "serviço de verdade": liga sozinho
  # no boot, reinicia se cair, e você controla com:
  #   systemctl start cs2-server
  #   systemctl stop cs2-server
  #   systemctl status cs2-server
  #   journalctl -u cs2-server -f      (ver logs ao vivo)
  #
  # Está desabilitado por padrão (enable = false). Ajuste o ExecStart com
  # o caminho real do seu servidor depois de baixá-lo via steamcmd, e troque
  # "SEU_USUARIO" pelo mesmo usuário que você configurou na seção 6.

  systemd.services.cs2-server = {
    description = "Servidor dedicado CS2 (SRCDS)";
    enable = false; # <-- mude para true quando o servidor estiver instalado
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # wantedBy = [ "multi-user.target" ]; # descomente pra iniciar junto com o boot

    serviceConfig = {
      Type = "simple";
      User = "nap"; # <-- TROQUE pelo seu usuário (mesmo da seção 6)
      WorkingDirectory = "/srv/srcds/cs2";

      # Ajuste o comando conforme a documentação do jogo. Exemplo para CS2:
      ExecStart = ''
        /srv/srcds/cs2/game/bin/linuxsteamrt64/cs2 -dedicated \
          -port 27015 \
          +map de_dust2 \
          +game_type 0 +game_mode 1 \
          -maxplayers 10
      '';

      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # --- Como instalar/atualizar o servidor (faça manualmente uma vez) -----
  # mkdir -p /srv/srcds/cs2 && sudo chown $USER:$USER /srv/srcds/cs2
  # steamcmd +force_install_dir /srv/srcds/cs2 +login anonymous \
  #   +app_update 730 validate +quit
  #
  # Pra outros jogos, troque o "app_update <ID>" pelo App ID do servidor
  # dedicado (TF2 = 232250, GMod = 4020, CS:GO legado = 740, etc) e crie
  # um bloco systemd novo igual ao do cs2-server acima, copiando e
  # ajustando o nome/porta/comando.

  # ==========================================================================
  # 12. EXTRAS / MANUTENÇÃO DO SISTEMA
  # ==========================================================================

  # Limpeza automática do Nix store: remove geração antigas com mais de 14
  # dias, evitando que o disco lote com versões antigas de pacotes.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Otimiza o Nix store automaticamente (deduplica arquivos idênticos).
  nix.settings.auto-optimise-store = true;

  # Habilita "flakes" e o novo comando "nix" — não obrigatório aqui, mas
  # deixa o sistema pronto caso você queira migrar para flakes no futuro.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Mantenha a mesma versão do "state" que você tinha na instalação original
  # do NixOS. NÃO mude este valor depois de instalado — ele só existe pra
  # evitar problemas de migração de dados entre versões do NixOS.
  system.stateVersion = "26.05"; # <-- mantenha igual ao que o instalador gerou
}

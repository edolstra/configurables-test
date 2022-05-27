{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }: rec {

    lib.configurationAdapter = { nixpkgs, system, modules }: {

      type = "configurable";

      options =
        let
          recurse = x:
            if x._type or "" == "option"
            then {
              type = "option";
              description = x.description or "";
              typeId = x.type.name;
              typeDescription = x.type.description;
            }
            else builtins.mapAttrs (name: value: recurse value) x // { type = "optionSet"; };
        in recurse (nixpkgs.lib.nixosSystem { inherit system; inherit modules; }).options;

      build = overrides: (nixpkgs.lib.nixosSystem {
        system = overrides.nixpkgs.system or system;
        modules = modules ++ [ (nixpkgs.lib.mapAttrsRecursive (path: value: nixpkgs.lib.mkForce value) overrides) ];
      }).config.system.build.toplevel;

    };

    nixosConfigurations2.test = self.lib.configurationAdapter {
      inherit nixpkgs;
      system = "x86_64-linux";
      modules = [
        {
          fileSystems."/".device = "/dev/sda2";
          boot.loader.grub.devices = [ "/dev/sda1" ];
          networking.hostName = "foobar";
        }
      ];
    };

    nixosConfigurations.test.config.system.build.toplevel = self.nixosConfigurations2.test.build {};

    #checks.x86_64-linux.default = nixosConfigurations2.test;
    checks.x86_64-linux.default = nixosConfigurations.test.config.system.build.toplevel;

  };
}

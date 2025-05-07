# PZ-cli-automod
# Project Zomboid Mod Manager

A simple **Bash**-based CLI tool to help manage mods in your Project Zomboid server configuration (`.ini`) file. You can **add**, **list**, and **remove** mods (Mod IDs and Workshop IDs) interactively without manually editing the file.

## Features

* **Interactive CLI menu**: run `./script.sh` and choose what to do.
* **Add mods** by pasting Steam Workshop URLs (automatically extracts Mod ID & Workshop ID).
* **List mods**: view installed mods with their index, Mod ID, and Workshop ID.
* **Delete mods**: remove a mod by name (removes both Mod ID & corresponding Workshop ID).
* **Safe file editing**: uses a temporary file to avoid corrupting your config.

## Prerequisites

* Linux environment with **Bash** (v4+).
* Standard Unix tools installed:

  * `grep`, `sed`, `awk`, `cut`, `curl`, `mktemp`
* Network access to Steam Workshop pages for fetching mod details.

## Installation

1. Clone or download this repository:

   ```bash
   git clone https://github.com/yourusername/pz-mod-manager.git
   cd pz-mod-manager
   ```
2. Make the script executable:

   ```bash
   chmod +x script.sh
   ```

## Usage

1. **Run the script**:

   ```bash
   ./script.sh
   ```
2. **Enter the path** to your Project Zomboid server `.ini` file when prompted:

   ```text
   Enter path to Project Zomboid server .ini file: servertest.ini
   ```
3. **Interact with the CLI**:

   * Paste a Steam Workshop URL to **add** a mod.
   * Type `list` to **view** current mods.
   * Type `delete <ModID>` to **remove** a mod.
   * Type `help` to show the **help** menu.
   * Type `exit` to **quit**.

### Example session

```text
$ ./script.sh
Enter path to Project Zomboid server .ini file: servertest.ini
Type 'help' for commands. Paste a Steam Workshop URL to add a mod.
> list
No mods installed.
> https://steamcommunity.com/sharedfiles/filedetails/?id=2200148440
Added Mod ID 'Brita' (Workshop ID 2200148440).
> list
Installed mods:
  1. Brita (WorkshopID: 2200148440)
> delete Brita
Removed 'Brita'.
> exit
Exiting.
```

## Script Breakdown

* **Main Loop**: Reads user input and dispatches commands (`add`, `list`, `delete`, `help`, `exit`).
* \`\`: Extracts IDs from the URL, checks for duplicates, and safely updates the `.ini`.
* \`\`: Parses the `Mods` and `WorkshopItems` lines, splitting on `;`, then prints each entry.
* \`\`: Finds a Mod ID by name, removes it and its corresponding Workshop ID, and rewrites the file.

See comments in `script.sh` for detailed explanations of each step.

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/awesome-feature`).
3. Commit your changes (`git commit -am 'Add awesome feature'`).
4. Push to the branch (`git push origin feature/awesome-feature`).
5. Open a Pull Request.

## License

This project is licensed under the [MIT License](LICENSE). Feel free to use and modify!



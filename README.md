# ros2_mix_pkg

Example ROS 2 (Humble) package with **both C++ and Python 3 nodes** in a single `ament_cmake` package. Use it as a starting template for your own packages.

## Package structure

```
ros2_mix_pkg/
├── CMakeLists.txt              # Builds the C++ node and installs the Python code
├── package.xml                 # Package name, version and dependencies
├── rename_pkg.sh               # Script to rename the package
├── config/
│   └── example.yaml            # Node parameters
├── include/example_pkg/        # C++ headers
├── launch/
│   └── example_launch.py       # Launches the Python node with the config file
├── ros2_mix_pkg/
│   └── __init__.py             # Python module (importable from your scripts)
├── scripts/
│   └── example_pkg_node.py     # Python node (publishes "Hello World" on /topic)
└── src/
    └── example_pkg_cpp_node.cpp  # C++ node (logs a message every 0.5 s)
```

## Build

Clone into the `src` folder of your workspace and build:

```bash
cd ~/ws/src
git clone https://github.com/RoBorregos/ros2_pkg.git
cd ~/ws
colcon build --packages-select ros2_mix_pkg
source install/setup.bash
```

## Run

```bash
# C++ node
ros2 run ros2_mix_pkg cpp_executable

# Python node
ros2 run ros2_mix_pkg example_pkg_node.py

# Launch file (Python node + config/example.yaml)
ros2 launch ros2_mix_pkg example_launch.py
```

## Rename the package

To use this as a template for a new package, rename it with:

```bash
./rename_pkg.sh -n my_new_pkg   # dry run: shows what would change
./rename_pkg.sh my_new_pkg      # apply
```

The script updates the name in `package.xml`, `CMakeLists.txt`, launch files and this README, and renames the Python module folder. Names must be lowercase letters, digits and `_`, starting with a letter.

After renaming, remove the old build artifacts and rebuild:

```bash
cd ~/ws
rm -rf build/<old_name> install/<old_name>
colcon build --packages-select my_new_pkg
```

## Adding your own nodes

**C++**: add the source file in `src/` and register it in `CMakeLists.txt`:

```cmake
add_executable(my_node src/my_node.cpp)
ament_target_dependencies(my_node rclcpp)
install(TARGETS my_node DESTINATION lib/${PROJECT_NAME})
```

**Python**: add the script in `scripts/` starting with `#!/usr/bin/env python3`, make it executable (`chmod +x`), and add it to `install(PROGRAMS ...)` in `CMakeLists.txt`:

```cmake
install(PROGRAMS
  scripts/example_pkg_node.py
  scripts/my_node.py
  DESTINATION lib/${PROJECT_NAME}
)
```

Run it with its file name: `ros2 run ros2_mix_pkg my_node.py`.

Shared Python code can go in the `ros2_mix_pkg/` module and be imported from your scripts with `from ros2_mix_pkg import ...`.

**Dependencies**: add every new dependency to `package.xml` (`<depend>...</depend>`) and to `CMakeLists.txt` (`find_package(...)`).

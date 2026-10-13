# make: latte-events.so, for the Hyprland that is installed (needs hyprland-devel, as hyprbars does).
# It goes to /usr/lib64/latteos/latte-events.so and has to be built again when Hyprland is updated.
CXXFLAGS ?= -O2
CXXFLAGS += -shared -fPIC -std=c++2b -Wno-c++11-narrowing --no-gnu-unique
INCLUDES = `pkg-config --cflags pixman-1 libdrm hyprland libinput libudev wayland-server xkbcommon`

latte-events.so: main.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) $^ -o $@

clean:
	rm -f latte-events.so

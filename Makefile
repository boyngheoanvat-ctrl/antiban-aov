CXX = clang++
CXXFLAGS = -std=c++17 -Wall -fPIC -framework Foundation
LDFLAGS = -lpthread

TARGET = libcleaner.dylib
SRC = Cleaner.mm

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -dynamiclib $(SRC) -o $(TARGET) $(LDFLAGS)

clean:
	rm -f $(TARGET)

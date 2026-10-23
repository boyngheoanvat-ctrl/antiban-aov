CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -pthread
TARGET = net_lag_demo
SRC = net_lag.cpp main.cpp

ifeq ($(OS),Windows_NT)
    LIBS = -lws2_32
else
    LIBS = 
endif

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET) $(LIBS)

clean:
	rm -f $(TARGET)

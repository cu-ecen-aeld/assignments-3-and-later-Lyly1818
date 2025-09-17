# Compiler
CC := $(CROSS_COMPILE)gcc

# Compiler flags
CFLAGS = -Wall -g

# Target executable
TARGET = writer

# Source files
SRC = writer.c
OBJ = $(SRC:.c=.o)

# Default target
all: $(TARGET)

# Linking
$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(TARGET)

# Compile .c -> .o
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up build artifacts
.PHONY: clean
clean:
	rm -f $(OBJ) $(TARGET)

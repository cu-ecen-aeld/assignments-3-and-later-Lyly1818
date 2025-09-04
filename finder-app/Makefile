CC := $(CROSS_COMPILE)gcc
CFLAGS = -Wall -g
TARGET= writer

SRC:=writer.c
OBJ:= $(SRC:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS)  $(OBJ) -o $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean
clean:
	rm -f $(OBJ) $(TARGET)	

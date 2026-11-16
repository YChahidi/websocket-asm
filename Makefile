AS = as
ASFLAGS = --64
LD = ld
OBJS = main.o socket_utils.o http_handler.o file_utils.o response_utils.o data.o websocket.o websocket_frames.o

server: $(OBJS)
	$(LD) -o server $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@

clean:
	rm -f *.o server

.PHONY: clean

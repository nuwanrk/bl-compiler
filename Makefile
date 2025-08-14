default:
	@cd src;zig run main.zig 

test:
	@cd src;zig test *.zig

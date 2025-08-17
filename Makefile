default:
	@cd src;zig run main.zig 

lex1:
	zig build run -- lex assets/func1.bal

test:
	@cd src;zig test *.zig

test1:
	zig build test

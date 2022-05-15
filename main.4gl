IMPORT util
# CALL srand() before rand!!!

PUBLIC CONSTANT X_MAXIMUM = 20
PUBLIC CONSTANT Y_MAXIMUM = 20

PUBLIC CONSTANT MAX_FRUITS = 1

PRIVATE CONSTANT DIRECTION_UP = 0
PRIVATE CONSTANT DIRECTION_DOWN = 1
PRIVATE CONSTANT DIRECTION_RIGHT = 2
PRIVATE CONSTANT DIRECTION_LEFT = 3

PRIVATE CONSTANT BORDER_HORIZONTAL_CHAR = "═"
PRIVATE CONSTANT BORDER_VERTICAL_CHAR = "║"
PRIVATE CONSTANT BORDER_TOP_LEFT_CHAR = "╔"
PRIVATE CONSTANT BORDER_TOP_RIGHT_CHAR = "╗"
PRIVATE CONSTANT BORDER_BOTTOM_LEFT_CHAR = "╚"
PRIVATE CONSTANT BORDER_BOTTOM_RIGHT_CHAR = "╝"

PRIVATE CONSTANT TILE_MAP = " "
PRIVATE CONSTANT TILE_SNAKE_HEAD = "▒"
PRIVATE CONSTANT TILE_SNAKE_BODY = "░"
PRIVATE CONSTANT TILE_FRUIT = "▓"

PRIVATE CONSTANT TICK_SPEED = 1

PUBLIC TYPE COORDINATE RECORD
    x INTEGER,
    y INTEGER
END RECORD

PUBLIC TYPE SNAKE RECORD
    segments DYNAMIC ARRAY OF COORDINATE,
    direction INTEGER
END RECORD

DEFINE
    score INTEGER,
    player SNAKE,
    fruits DYNAMIC ARRAY OF COORDINATE,
    is_game_running BOOLEAN,
    key_up, key_down, key_right, key_left INTEGER,
	key_q INTEGER,
    x_inner_max INTEGER,
    y_inner_max INTEGER,
	screen_rows DYNAMIC ARRAY OF STRING

MAIN

    WHENEVER ERROR STOP
	
	OPEN WINDOW main_window WITH FORM "screen"
    
	CALL _run_dialog()
	
	#CALL _run_game()

END MAIN



PRIVATE FUNCTION _run_dialog()

	DIALOG ATTRIBUTES (UNBUFFERED)

		BEFORE DIALOG
			CALL _initialize()
			#CALL _run_game()
		
		DISPLAY ARRAY screen_rows TO sr_display.*
		END DISPLAY
		
		ON ACTION set_direction_up ATTRIBUTES(ACCELERATOR="Up")
			LET player.direction = DIRECTION_UP
		ON ACTION set_direction_down ATTRIBUTES(ACCELERATOR="Down")
			LET player.direction = DIRECTION_DOWN
		ON ACTION set_direction_left ATTRIBUTES(ACCELERATOR="Left")
			LET player.direction = DIRECTION_LEFT
		ON ACTION set_direction_right ATTRIBUTES(ACCELERATOR="Right")
			LET player.direction = DIRECTION_RIGHT
		
		ON TIMER TICK_SPEED
			IF (is_game_running) THEN
				CALL _move_snake()
				CALL _display()
				CALL ui.Interface.refresh()
				SLEEP 1
			ELSE
				CALL _game_over()
			END IF
		
		ON ACTION close
			EXIT DIALOG

	END DIALOG

END FUNCTION



PRIVATE FUNCTION _run_game()

    CALL _initialize()

    WHILE (is_game_running)
        CALL _move_snake()
        CALL _display()
        SLEEP 1
    END WHILE

    CALL _game_over()

END FUNCTION



PRIVATE FUNCTION _display()
    DEFINE
        i INTEGER,
        j INTEGER,
        screen DYNAMIC ARRAY WITH DIMENSION 2 OF CHAR,
        screen_height INTEGER,
        screen_length INTEGER,
        row STRING

    LET x_inner_max = X_MAXIMUM - 1
    LET y_inner_max = Y_MAXIMUM - 1

    CALL _construct_borders(screen)

    FOR i = 2 TO y_inner_max
        FOR j = 2 TO x_inner_max
            LET screen[j, i] = TILE_MAP
        END FOR
    END FOR
    
    CALL _draw_snake(screen)
    CALL _draw_fruits(screen)
    
    
    LET screen_length = screen.getLength()
    LET screen_height = screen[screen_length].getLength()
    FOR i = screen_height TO 1 STEP -1
        LET row = ""
        FOR j = 1 TO screen_length
            LET row = row, screen[j,i]
        END FOR
		LET screen[i] = row
        #DISPLAY row
    END FOR

END FUNCTION



PRIVATE FUNCTION _draw_snake(
        screen DYNAMIC ARRAY WITH DIMENSION 2 OF CHAR
    )
    
    DEFINE
        i INTEGER,
        array_length INTEGER
        
    LET screen[player.segments[1].x, player.segments[1].y] = TILE_SNAKE_HEAD
    
    LET array_length = player.segments.getLength()
    
    FOR i = 2 TO array_length
        LET screen[player.segments[i].x, player.segments[i].y] = TILE_SNAKE_BODY
    END FOR
    
END FUNCTION



PRIVATE FUNCTION _draw_fruits(
        screen DYNAMIC ARRAY WITH DIMENSION 2 OF CHAR
    )
    
    DEFINE
        i INTEGER,
        array_length INTEGER
        
    LET array_length = fruits.getLength()
    
    FOR i = 1 TO array_length
        LET screen[fruits[i].x, fruits[i].y] = TILE_FRUIT
    END FOR
    
    
END FUNCTION



PRIVATE FUNCTION _construct_borders(
    screen DYNAMIC ARRAY WITH DIMENSION 2 OF CHAR
    )

    DEFINE
        i INTEGER

    LET screen[1,1] = BORDER_BOTTOM_LEFT_CHAR
    LET screen[X_MAXIMUM, 1] = BORDER_BOTTOM_RIGHT_CHAR
    LET screen[1, Y_MAXIMUM] = BORDER_TOP_LEFT_CHAR
    LET screen[X_MAXIMUM, Y_MAXIMUM] = BORDER_TOP_RIGHT_CHAR
    
    FOR i = 2 TO y_inner_max
        LET screen[1, i] = BORDER_VERTICAL_CHAR
        LET screen[X_MAXIMUM, i] = BORDER_VERTICAL_CHAR
    END FOR

    FOR i = 2 TO x_inner_max
        LET screen[i, 1] = BORDER_HORIZONTAL_CHAR
        LET screen[i, Y_MAXIMUM] = BORDER_HORIZONTAL_CHAR
    END FOR

END FUNCTION



PRIVATE FUNCTION _initialize()
    DEFINE
        start_position COORDINATE,
        i INTEGER

    LET start_position.x = X_MAXIMUM / 2
    LET start_position.y = Y_MAXIMUM / 2

    LET player.segments[1].* = start_position.*

    FOR i = 1 TO MAX_FRUITS
        #CALL fruits.appendElement()
        CALL _add_fruit()
    END FOR

    LET key_up = fgl_keyval("UP")
    LET key_down = fgl_keyval("DOWN")
    LET key_right = fgl_keyval("RIGHT")
    LET key_left = fgl_keyval("LEFT")
    
	LET key_q = fgl_keyval("CONTROL-Q")
	
    LET is_game_running = TRUE

END FUNCTION



PRIVATE FUNCTION _game_over()
    DISPLAY "Game over, score: ", score USING "<<<<<<<&"
END FUNCTION



PRIVATE FUNCTION _move_snake()

    #LET player.direction = fgl_lastkey()

    CASE player.direction
        WHEN player.direction = DIRECTION_UP
        #WHEN player.direction = key_up
            LET player.segments[1].y = player.segments[1].y + 1
            IF (player.segments[1].y > Y_MAXIMUM) THEN
                CALL _end_game()
            END IF
        WHEN player.direction = DIRECTION_DOWN
        #WHEN player.direction = key_down
            LET player.segments[1].y = player.segments[1].y - 1
            IF (player.segments[1].y <= 0) THEN
                CALL _end_game()
            END IF
        WHEN player.direction = DIRECTION_RIGHT
        #WHEN player.direction = key_right
            LET player.segments[1].x = player.segments[1].x + 1
            IF (player.segments[1].x > X_MAXIMUM) THEN
                CALL _end_game()
            END IF
        WHEN player.direction = DIRECTION_LEFT
        #WHEN player.direction = key_left
            LET player.segments[1].x = player.segments[1].x - 1
            IF (player.segments[1].x <= 0) THEN
                CALL _end_game()
            END IF
        #OTHERWISE
    END CASE

    CALL _update_snake_segments()
    CALL _check_fruits()
    

END FUNCTION



PRIVATE FUNCTION _update_snake_segments()
    DEFINE
        i INTEGER,
        snake_length INTEGER

    LET snake_length = player.segments.getLength()
    FOR i = 2 TO snake_length
        LET player.segments[i].x = player.segments[i - 1].x
        LET player.segments[i].y = player.segments[i - 1].y
    END FOR

END FUNCTION



PRIVATE FUNCTION _check_fruits()
    DEFINE
        i INTEGER,
        fruits_length INTEGER

    LET fruits_length = fruits.getLength()

    FOR i = 1 TO fruits_length
        IF (_is_coordinate_equal(player.segments[1].*, fruits[i].*)) THEN
            CALL _snake_add_segment()
            CALL fruits.deleteElement(i)
            CALL _add_fruit()
            EXIT FOR
        END IF
    END FOR

END FUNCTION



PRIVATE FUNCTION _is_coordinate_equal(
        coordinate_one COORDINATE,
        coordinate_two COORDINATE
    ) RETURNS BOOLEAN

    IF ((coordinate_one.x == coordinate_two.x)
        AND (coordinate_one.y == coordinate_two.y)) THEN
        RETURN TRUE
    END IF

    RETURN FALSE
END FUNCTION



PRIVATE FUNCTION _snake_add_segment()
    CALL player.segments.appendElement()
END FUNCTION

PRIVATE FUNCTION _add_fruit()
    DEFINE
        position COORDINATE,
        valid_position BOOLEAN

    LET valid_position = FALSE
    CALL fruits.appendElement()

    WHILE (NOT valid_position)
        LET position.x = util.Math.rand(X_MAXIMUM)
        LET position.y = util.Math.rand(Y_MAXIMUM)

        IF (NOT _in_snake(position.*)) THEN
            IF (NOT _in_fruits(position.*)) THEN
                LET valid_position = TRUE
            END IF
        END IF
    END WHILE

    LET fruits[fruits.getLength()].* = position.*
    CALL _update_score()
END FUNCTION

PRIVATE FUNCTION _end_game()
    LET is_game_running = FALSE
END FUNCTION

PRIVATE FUNCTION _in_snake(position COORDINATE) RETURNS BOOLEAN
    DEFINE
        i INTEGER,
        snake_length INTEGER

    LET snake_length = player.segments.getLength()

    FOR i = 1 TO snake_length
        IF (_is_coordinate_equal(position.*, player.segments[i].*)) THEN
            RETURN TRUE
        END IF
    END FOR

    RETURN FALSE
END FUNCTION



PRIVATE FUNCTION _in_fruits(position COORDINATE) RETURNS BOOLEAN
    DEFINE
        i INTEGER,
        fruits_length INTEGER

    LET fruits_length = fruits.getLength()

    FOR i = 1 TO fruits_length
        IF (_is_coordinate_equal(position.*, fruits[i].*)) THEN
            RETURN TRUE
        END IF
    END FOR

    RETURN FALSE
END FUNCTION



PRIVATE FUNCTION _update_score()
    LET score = player.segments.getLength()
END FUNCTION
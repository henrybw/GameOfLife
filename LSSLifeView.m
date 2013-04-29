//
// Game of Life Screen Saver
// LSSLifeView.m
// By Henry Weiss
//
// Conway's Game of Life...turned into a screen saver! In addition to using a configurable
// grid size, it also implements a "cell history" feature, based off a similar one from Mirek's
// Java Cellebration. And, yes, this has probably been done many times before, and they're
// probably a lot better too, but oh well. Another Game of Life screen saver can't hurt, can it?
//
// The "LSS" prefix stands for "Life Screen Saver."
//

#import "LSSLifeView.h"

@implementation LSSLifeView

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
	if (self = [super initWithFrame:frame isPreview:isPreview])
	{
		// Set the factory default options
		NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithBool:NO], kDrawGridLinesPref,
								  [NSNumber numberWithInt:100], kGridWidthPref,
								  [NSNumber numberWithInt:75], kGridHeightPref,
								  [NSArchiver archivedDataWithRootObject:[NSColor blackColor]], kGridBGColorPref,
								  [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], kGridLineColorPref,
								  [NSArchiver archivedDataWithRootObject:[NSColor blueColor]], kCellStartColorPref,
								  [NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.2 alpha:1.0]], kCellEndColorPref,
								  [NSNumber numberWithFloat:12.0f], kGensPerSecPref,
								  [NSNumber numberWithInt:1], kRandomCellsPref,
								  nil];
		
		// Register the factory defaults
		ScreenSaverDefaults *prefs = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
		[prefs registerDefaults:defaults];
		
		// Init the array to nil
		cells = nil;
	}
	
	return self;
}

// Initializes the board first and caches some of the preference values before starting the animation

- (void)startAnimation
{
	ScreenSaverDefaults *prefs = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	
	// Release our cached variables to get the reference count down to zero
	[bgColor release];
	[gridColor release];
	[cellStartColor release];
	[cellEndColor release];
	
	// Cache certain variables first
	shouldDrawGrid = [prefs boolForKey:kDrawGridLinesPref];
	bgColor = [[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kGridBGColorPref]] retain];
	gridColor = [[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kGridLineColorPref]] retain];
	cellStartColor = [[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kCellStartColorPref]] retain];
	cellEndColor = [[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kCellEndColorPref]] retain];
	randomCells = [prefs integerForKey:kRandomCellsPref];
	
	// Free the memory allocated for the grid if we
	// have already allocated it before
	
	if (cells != nil)
	{
		for (int i = 0; i < gridHeight; i++)
		{
			free(cells[i]);
		}
		
		free(cells);
	}
	
	// Now access the grid dimensions (prevents it from
	// screwing up the free() calls above).
	gridWidth = [prefs integerForKey:kGridWidthPref];
	gridHeight = [prefs integerForKey:kGridHeightPref];
	
	// Scale down the grid size if this is a preview
	
	if ([self isPreview])
	{
		gridWidth *= 0.75;
		gridHeight *= 0.75;
		randomCells = MAX(randomCells * 0.75, 1);  // Make sure we don't stagnate, even if the user specifies 0
	}
	
	// Cache certain calculations
	rowHeight = ([self frame].size.height / gridHeight);
	colWidth = ([self frame].size.width / gridWidth);
	
	// Now allocate the arrays for the game state
	cells = (Cell **)calloc(gridHeight, sizeof(Cell *));
	
	for (int i = 0; i < gridHeight; i++)
	{
		cells[i] = (Cell *)calloc(gridWidth, sizeof(Cell));
	}
	
	// Initialize the cells to a random state
	[self randomizeGrid];
	
	// And now we can start the animation
	[self setAnimationTimeInterval:(1 / [prefs floatForKey:kGensPerSecPref])];
	[super startAnimation];
}

- (void)stopAnimation
{
	[super stopAnimation];
}

// Randomly regenerates the cell population to a random state (each cell has
// a 1/5 chance of being alive). This is called at the beginning and whenever
// the cell population dies.

- (void)randomizeGrid
{
	for (int row = 0; row < gridHeight; row++)
	{
		for (int col = 0; col < gridWidth; col++)
		{
			if (SSRandomIntBetween(1, 5) == 1)
			{
				cells[row][col].alive = YES;
				cells[row][col].age = 0;
			}
			
			else
			{
				cells[row][col].alive = NO;
				cells[row][col].age = -1;
			}
		}
	}
}

// Pressing G toggles grid lines

- (void)keyDown:(NSEvent *)event
{
	if ([[event charactersIgnoringModifiers] isEqualToString:@"g"])
	{
		shouldDrawGrid = !shouldDrawGrid;
	}
	
	else
	{
		[super keyDown:event];
	}
}

// Updates the board state

- (void)animateOneFrame
{
	// Insert some random cells to prevent deadlock
	
	for (int i = 0; i < randomCells; i++)
	{
		int row = SSRandomIntBetween(0, gridHeight - 1);
		int col = SSRandomIntBetween(0, gridWidth - 1);
		
		cells[row][col].alive = YES;
		cells[row][col].age = MAX(0, cells[row][col].age);
	}
	
	// Calculate how many neighbors each cell has
	int neighbors[gridHeight][gridWidth];
	
	for (int row = 0; row < gridHeight; row++)
	{
		for (int col = 0; col < gridWidth; col++)
		{
			// Set the bounds to search
			int minRow = MAX(row - 1, 0);
			int maxRow = MIN(row + 1, gridHeight - 1);
			int minColumn = MAX(col - 1, 0);
			int maxColumn = MIN(col + 1, gridWidth - 1);
			
			// Adjust for current cell
			int numberNeighbors = 0;
			
			if (cells[row][col].alive)
				numberNeighbors = -1;
			
			// Count the number of live neighbors
			
			for (int i = minRow; i <= maxRow; i++)
			{
				for (int j = minColumn; j <= maxColumn; j++)
				{
					if (cells[i][j].alive)
						numberNeighbors++;
				}
			}
			
			neighbors[row][col] = numberNeighbors;
		}
	}
	
	// Update the generation
	BOOL liveCellFound = NO;  // Checks if the entire population died out
	
	for (int row = 0; row < gridHeight; row++)
	{
		for (int col = 0; col < gridWidth; col++)
		{
			if (cells[row][col].alive)
			{
				if (neighbors[row][col] == 2 || neighbors[row][col] == 3)
				{
					cells[row][col].alive = YES;
					cells[row][col].age = MIN(cells[row][col].age + 1, kMaxCellAge);  // Bounds checking
				}
				
				else
				{
					cells[row][col].alive = NO;
					cells[row][col].age = -1;
				}
			}
			
			else
			{
				if (neighbors[row][col] == 3)
				{
					cells[row][col].alive = YES;
					cells[row][col].age++;  // Cell was age -1 before, so we don't have to do bounds checking
				}
				
				else
				{
					cells[row][col].alive = NO;
					cells[row][col].age = 0;
				}
			}
			
			// Is this cell alive? If so, then we have at least one live cell,
			// so we won't have to randomly regenerate the cell grid.
			liveCellFound = liveCellFound || cells[row][col].alive;
		}
	}
	
	if (!liveCellFound)
	{
		// Randomly respawn the population
		[self randomizeGrid];
	}
	
	// Draw the current board state
	[self setNeedsDisplay:YES];
}

// Board rendering

- (void)drawRect:(NSRect)rect
{
	// Draw the background first
	[bgColor set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
	
	// Draw the grid lines (if allowed to do so)
	
	if (shouldDrawGrid)
	{
		[gridColor set];
		cachedPath = [NSBezierPath bezierPath];
		
		// Draw a big box around the frame
		[cachedPath setLineWidth:1.0f];
		[cachedPath appendBezierPath:[NSBezierPath bezierPathWithRect:rect]];
		[cachedPath stroke];
		[cachedPath setLineWidth:0.5f];
		
		// Draw all the horizontal lines first
		
		for (int i = 0; i < gridHeight; i++)
		{
			[cachedPath moveToPoint:NSMakePoint(0, i * rowHeight)];
			[cachedPath lineToPoint:NSMakePoint(rect.size.width, i * rowHeight)];
		}
		
		// Then draw all the vertical lines
		
		for (int i = 0; i < gridWidth; i++)
		{
			[cachedPath moveToPoint:NSMakePoint(i * colWidth, 0)];
			[cachedPath lineToPoint:NSMakePoint(i * colWidth, rect.size.height)];
		}
		
		[cachedPath stroke];
	}
	
	// Draw the board
	
	for (int row = 0; row < gridHeight; row++)
	{
		for (int col = 0; col < gridWidth; col++)
		{
			// Only draw if alive
			
			if (cells[row][col].alive)
			{
				NSBezierPath *path = [NSBezierPath bezierPath];
				float age = (float)cells[row][col].age;  // Typecasted for later calcuations
				
				// Calculate the current color based on age (i.e. how much it has faded to the end color)
				NSColor *currentColor = [cellStartColor blendedColorWithFraction:(age / kMaxCellAge) ofColor:cellEndColor];
				
				if (!currentColor)
					currentColor = cellStartColor;  // If it can't be blended for some reason
				
				[currentColor set];
				
				// Draw the cell rect
				NSRect cellRect = NSMakeRect(col * colWidth, row * rowHeight, colWidth, rowHeight);
				[path appendBezierPathWithRect:cellRect];
				[path fill];
			}
		}
	}
}

// Configuration stuff

- (BOOL)hasConfigureSheet
{
	return YES;
}

- (NSWindow *)configureSheet
{
	// Load the sheet if it hasn't been loaded
	
	if (!configSheet)
	{
		if (![NSBundle loadNibNamed:@"ConfigSheet" owner:self])
		{
			NSRunAlertPanel(NSLocalizedString(@"Couldn't load the options sheet", @"Bundle load error"),
							NSLocalizedString(@"This is probably an internal error. Try reinstalling the screen saver. If the problem persists, contact the developer.",
											  @"Bundle load error description."),
							@"OK", nil, nil);
		}
	}
	
	// Load the preferences into the sheet
	ScreenSaverDefaults *prefs = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
	
	[drawGridLinesSwitch setState:[prefs boolForKey:kDrawGridLinesPref]];
	[widthField setIntValue:[prefs integerForKey:kGridWidthPref]];
	[heightField setIntValue:[prefs integerForKey:kGridHeightPref]];
	[bgColorWell setColor:[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kGridBGColorPref]]];
	[gridColorWell setColor:[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kGridLineColorPref]]];
	[cellStartColorWell setColor:[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kCellStartColorPref]]];
	[cellEndColorWell setColor:[NSUnarchiver unarchiveObjectWithData:[prefs objectForKey:kCellEndColorPref]]];
	[gensField setFloatValue:[prefs floatForKey:kGensPerSecPref]];
	[randCellField setIntValue:[prefs integerForKey:kRandomCellsPref]];
	
	return configSheet;
}

- (IBAction)endConfigSheet:(id)sender
{
	// Was this an OK?
	
	if ([sender tag] == NSOKButton)
	{
		ScreenSaverDefaults *prefs = [ScreenSaverDefaults defaultsForModuleWithName:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
		
		// Save the preferences
		[prefs setBool:[drawGridLinesSwitch state] forKey:kDrawGridLinesPref];
		[prefs setInteger:MAX(MIN([widthField intValue], kMaxCellWidth), kMinCellWidth) forKey:kGridWidthPref];
		[prefs setInteger:MAX(MIN([heightField intValue], kMaxCellHeight), kMinCellHeight) forKey:kGridHeightPref];
		[prefs setObject:[NSArchiver archivedDataWithRootObject:[bgColorWell color]] forKey:kGridBGColorPref];
		[prefs setObject:[NSArchiver archivedDataWithRootObject:[gridColorWell color]] forKey:kGridLineColorPref];
		[prefs setObject:[NSArchiver archivedDataWithRootObject:[cellStartColorWell color]] forKey:kCellStartColorPref];
		[prefs setObject:[NSArchiver archivedDataWithRootObject:[cellEndColorWell color]] forKey:kCellEndColorPref];
		[prefs setFloat:MAX(MIN([gensField floatValue], kMaxGensPerSec), kMinGensPerSec) forKey:kGensPerSecPref];
		
		// The upper bound for the random cells depends on the current width/height
		int upperBound = MIN([prefs integerForKey:kGridHeightPref], [prefs integerForKey:kGridWidthPref]);
		[prefs setInteger:MAX(MIN([randCellField intValue], upperBound), 0) forKey:kRandomCellsPref];
		
		// Actually save changes now
		[prefs synchronize];
	}
	
	// Close out the sheet
	[[NSApplication sharedApplication] endSheet:configSheet];
}

@end
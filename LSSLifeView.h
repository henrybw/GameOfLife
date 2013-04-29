//
// Game of Life Screen Saver
// LSSLifeView.h
// By Henry Weiss
//

#import <ScreenSaver/ScreenSaver.h>

// Constants (pref keys)
#define kDrawGridLinesPref @"DrawGridLines"
#define kGridWidthPref @"GridWidth"
#define kGridHeightPref @"GridHeight"
#define kGridBGColorPref @"GridBGColor"
#define kGridLineColorPref @"GridLineColor"
#define kCellStartColorPref @"CellStartColor"
#define kCellEndColorPref @"CellEndColor"
#define kGensPerSecPref @"GensPerSec"
#define kRandomCellsPref @"RandomCellsPerStep"

// Other constants
const int kMaxCellAge = 6;  // 7 steps, i.e. from 0-6
const int kMinCellWidth = 20;
const int kMinCellHeight = 15;
const int kMaxCellWidth = 300;
const int kMaxCellHeight = 225;
const float kMaxGensPerSec = 60.0f;
const int kMinGensPerSec = 0.1f;

// The struct that represents each cell

typedef struct Cell
{
	BOOL alive;
	int age;
} Cell;

@interface LSSLifeView : ScreenSaverView 
{
	// Config sheet outlets
	IBOutlet NSWindow *configSheet;
	IBOutlet NSButton *drawGridLinesSwitch;
	IBOutlet NSTextField *widthField, *heightField, *gensField, *randCellField;
	IBOutlet NSColorWell *bgColorWell, *gridColorWell;
	IBOutlet NSColorWell *cellStartColorWell, *cellEndColorWell;
	
	// Game state (accessed in [row][col] format)
	Cell **cells;
	
	// Cached variables (saves some calculation/reading from the user defaults)
	NSBezierPath *cachedPath;
	int gridWidth, gridHeight, randomCells;
	float rowHeight, colWidth;
	NSColor *bgColor, *gridColor, *cellStartColor, *cellEndColor;
	BOOL shouldDrawGrid;
}

- (void)randomizeGrid;
- (void)keyDown:(NSEvent *)event;
- (IBAction)endConfigSheet:(id)sender;

@end
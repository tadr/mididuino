typedef enum {
  ARP_STYLE_UP = 0,
  ARP_STYLE_DOWN,
  ARP_STYLE_UPDOWN,
  ARP_STYLE_DOWNUP,
  ARP_STYLE_UP_AND_DOWN,
  ARP_STYLE_DOWN_AND_UP,
  ARP_STYLE_CONVERGE,
  ARP_STYLE_DIVERGE,
  ARP_STYLE_PINKY_UP,
  ARP_STYLE_PINKY_UPDOWN,
  ARP_STYLE_THUMB_UP,
  ARP_STYLE_THUMB_UPDOWN,
  ARP_STYLE_RANDOM,
  ARP_STYLE_RANDOM_ONCE,
  ARP_STYLE_ORDER,
  ARP_STYLE_CNT
} arp_style_t;

char arp_names[ARP_STYLE_CNT][8] PROGMEM = {
  "UP     ",
  "DOWN   ",
  "UPDOWN ",
  "DOWNUP ",
  "UP&DOWN",
  "DOWN&UP",
  "CONVERG",
  "DIVERGE",
  "PINK_UP",
  "PINK_UD",
  "THMB_UP",
  "THMB_UD",
  "RANDOM ",
  "RANDOM1",
  "ORDER  "
};

typedef enum {
  RETRIG_OFF = 0,
  RETRIG_NOTE,
  RETRIG_BEAT,
  RETRIG_CNT
} arp_retrig_type_t;

char retrig_names[RETRIG_CNT][5] PROGMEM = {
  "OFF ",
  "NOTE",
  "BEAT"
};

#define NUM_NOTES 8
#define MAX_ARP_LEN 64

class ArpeggiatorClass {
public:
  uint8_t notes[NUM_NOTES];
  uint8_t velocities[NUM_NOTES];

  uint8_t orderedNotes[NUM_NOTES];
  uint8_t orderedVelocities[NUM_NOTES];
  uint8_t numNotes;

  uint8_t arpNotes[MAX_ARP_LEN];
  uint8_t arpVelocities[MAX_ARP_LEN];
  
  uint8_t arpSpeed;
  uint8_t arpLen;
  uint8_t arpStep;
  uint8_t arpCount;
  uint8_t arpTrack;
  uint8_t arpTimes;
  uint8_t arpOctaves;
  uint8_t arpOctaveCount;
  uint8_t retrigSpeed;

  arp_style_t arpStyle;
  arp_retrig_type_t arpRetrig;

  uint16_t speedCounter;

  ArpeggiatorClass() {
    numNotes = 0;
    arpLen = 0;
    arpStep = 0;
    arpCount = 0;
    arpTimes = 0;
    arpStyle = ARP_STYLE_UP;
    arpRetrig = RETRIG_OFF;
    arpSpeed = 0;
    speedCounter = 0;
    arpTrack = 0;
    retrigSpeed = 1;
    arpOctaves = 0;
    arpOctaveCount = 0;

    for (int i = 0; i < NUM_NOTES; i++) {
      orderedNotes[i] = 128;
    }
  }
  
  void retrigger() {
    arpStep = 0;
    arpCount = 0;
    speedCounter = 0;
    arpOctaveCount = 0;
  }

  void bubbleSortUp() {
    bool completed = true;
    do {
      completed = true;
      for (int i = 0; i < numNotes-1; i++) {
        if (orderedNotes[i] > orderedNotes[i+1]) {
          completed = false;
          uint8_t tmp = orderedNotes[i];
          orderedNotes[i] = orderedNotes[i+1];
          orderedNotes[i+1] = tmp;
          tmp = orderedVelocities[i];
          orderedVelocities[i] = orderedVelocities[i+1];
          orderedVelocities[i+1] = tmp;
        }
      }
    } while (!completed);
  }

  void bubbleSortDown() {
    bool completed = true;
    do {
      completed = true;
      for (int i = 0; i < numNotes-1; i++) {
        if (orderedNotes[i] < orderedNotes[i+1]) {
          completed = false;
          uint8_t tmp = orderedNotes[i];
          orderedNotes[i] = orderedNotes[i+1];
          orderedNotes[i+1] = tmp;
          tmp = orderedVelocities[i];
          orderedVelocities[i] = orderedVelocities[i+1];
          orderedVelocities[i+1] = tmp;
        }
      }
    } while (!completed);
  }

  void calculateArp() {
    uint8_t tmp = SREG;
    cli();

    arpStep = 0;
    switch (arpStyle) {
    case ARP_STYLE_UP:
      bubbleSortUp();
      m_memcpy(arpNotes, orderedNotes, numNotes);
      m_memcpy(arpVelocities, orderedVelocities, numNotes);
      arpLen = numNotes;
      break;
    
    case ARP_STYLE_DOWN:
      bubbleSortDown();
      m_memcpy(arpNotes, orderedNotes, numNotes);
      m_memcpy(arpVelocities, orderedVelocities, numNotes);
      arpLen = numNotes;
      break;
    
    case ARP_STYLE_ORDER: {
      m_memcpy(arpNotes, orderedNotes, numNotes);
      m_memcpy(arpVelocities, orderedVelocities, numNotes);
      arpLen = numNotes;
    }
      break;
    
    case ARP_STYLE_UPDOWN:
      if (numNotes > 1) {
	bubbleSortUp();
	m_memcpy(arpNotes, orderedNotes, numNotes);
	m_memcpy(arpVelocities, orderedVelocities, numNotes);
	for (int i = 0; i < numNotes - 2; i++) {
	  arpNotes[numNotes + i] = orderedNotes[numNotes - 2 - i];
	  arpVelocities[numNotes + i] = arpVelocities[numNotes - 2 - i];
	}
	arpLen = numNotes + numNotes - 2;
      } else {
	arpNotes[0] = orderedNotes[0];
	arpVelocities[0] = orderedVelocities[0];
	arpLen = 1;
      }
      break;
  
    case ARP_STYLE_DOWNUP:
      if (numNotes > 1) {
	bubbleSortDown();
	m_memcpy(arpNotes, orderedNotes, numNotes);
	m_memcpy(arpVelocities, orderedVelocities, numNotes);
	for (int i = 0; i < numNotes - 2; i++) {
	  arpNotes[numNotes + i] = orderedNotes[numNotes - 2 - i];
	  arpVelocities[numNotes + i] = arpVelocities[numNotes - 2 - i];
	}
	arpLen = numNotes + numNotes - 2;
      } else {
	arpNotes[0] = orderedNotes[0];
	arpVelocities[0] = orderedVelocities[0];
	arpLen = 1;
      }
      break;
   
    case ARP_STYLE_UP_AND_DOWN:
      if (numNotes > 1) {
	bubbleSortUp();
	m_memcpy(arpNotes, orderedNotes, numNotes);
	m_memcpy(arpVelocities, orderedVelocities, numNotes);
	for (int i = 0; i < numNotes; i++) {
	  arpNotes[numNotes + i] = orderedNotes[numNotes - 1 - i];
	  arpVelocities[numNotes + i] = arpVelocities[numNotes - 1 - i];
	}
	arpLen = numNotes + numNotes;
      } else {
	arpNotes[0] = orderedNotes[0];
	arpVelocities[0] = orderedVelocities[0];
	arpLen = 1;
      }
      break;
   
    case ARP_STYLE_DOWN_AND_UP:
      if (numNotes > 1) {
	bubbleSortDown();
	m_memcpy(arpNotes, orderedNotes, numNotes);
	m_memcpy(arpVelocities, orderedVelocities, numNotes);
	for (int i = 0; i < numNotes; i++) {
	  arpNotes[numNotes + i] = orderedNotes[numNotes - 1 - i];
	  arpVelocities[numNotes + i] = arpVelocities[numNotes - 1 - i];
	}
	arpLen = numNotes + numNotes;
      } else {
	arpNotes[0] = orderedNotes[0];
	arpVelocities[0] = orderedVelocities[0];
	arpLen = 1;
      }
      break;
   
    case ARP_STYLE_CONVERGE:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_DIVERGE:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_PINKY_UP:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_PINKY_UPDOWN:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_THUMB_UP:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_THUMB_UPDOWN:
      bubbleSortUp();
      break;
   
    case ARP_STYLE_RANDOM:
      arpLen = numNotes;
      break;
   
    case ARP_STYLE_RANDOM_ONCE:
      bubbleSortUp();
      break;
   
    default:
      break;
    }

    SREG = tmp;
  }

  void reorderNotes() {
    uint8_t write = 0;
    for (int i = 0; i < NUM_NOTES; i++) {
      if (orderedNotes[i] != 128) {
	orderedNotes[write] = orderedNotes[i];
	orderedVelocities[write] = orderedVelocities[i];
	if (i != write)
	  orderedNotes[i] = 128;
	write++;
      }
    }
  }

  void addNote(uint8_t pitch, uint8_t velocity) {
    // replace
    bool replaced = false;
    for (int i = 0; i < NUM_NOTES; i++) {
      if (orderedNotes[i] == pitch) {
	orderedVelocities[i] = velocity;
	replaced = true;
      }
    }
    if (replaced)
      return;

    uint8_t replaceNote = 128;
    if (numNotes == NUM_NOTES) {
      orderedNotes[0] = 128;
      numNotes--;
      reorderNotes();
    }

    orderedNotes[numNotes] = pitch;
    orderedVelocities[numNotes] = velocity;
    numNotes++;
    
    calculateArp();
    if (arpRetrig == RETRIG_NOTE || numNotes == 1) {
      retrigger();
    }      
  }

  void removeNote(uint8_t pitch) {
    for (int i = 0; i < NUM_NOTES; i++) {
      if (orderedNotes[i] == pitch) {
	orderedNotes[i] = 128;
	reorderNotes();
	numNotes--;
	break;
      }
    }
    calculateArp();
  }

  void playNext() {
    if (arpLen == 0 || (arpTimes != 0 && arpCount >= arpTimes))
      return;
    if (arpRetrig == RETRIG_BEAT && (MidiClock.div16th_counter % retrigSpeed) == 0)
      retrigger();
    if (++speedCounter >= arpSpeed) {
      speedCounter = 0;
      if (arpStyle == ARP_STYLE_RANDOM) {
	uint8_t i = random(numNotes);
	MD.sendNoteOn(arpTrack, orderedNotes[i] + random(arpOctaves) * 12, orderedVelocities[i]);
      } else {
	MD.sendNoteOn(arpTrack, arpNotes[arpStep] + 12 * arpOctaveCount, arpVelocities[arpStep]);
	if (++arpStep == arpLen) {
          if (arpOctaveCount < arpOctaves) {
            arpStep = 0;
            arpOctaveCount++;
          } else {
  	    arpStep = 0;
            arpOctaveCount = 0;
            arpCount++;
          }
	}
      }
    } 
  }

};

ArpeggiatorClass arpeggiator;

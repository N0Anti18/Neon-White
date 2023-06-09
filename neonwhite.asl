state("Neon White") {
    long levelPlaythroughMicroseconds : "UnityPlayer.dll", 0x199CDC0, 0x18, 0x40, 0x28, 0x48, 0x20;
    long levelMicroseconds : "UnityPlayer.dll", 0x1930010, 0x10, 0xD0, 0x8, 0x60, 0x50, 0x0, 0x1C0, 0x10, 0x20;
    string255 levelId : "UnityPlayer.dll", 0x199CDC0, 0x18, 0x40, 0x28, 0x30, 0x20, 0x14;
    string255 levelScene : "UnityPlayer.dll", 0x1A058E0, 0x48, 0x10, 0x18;
}

startup {
    settings.Add("Rush", false);
    settings.Add("New Game", true);

    vars.MENU_SCENE = "nu.unity";
    vars.RUSH_START = new string[4]{
        "TUT_MOVEMENT",  // White's & Mikey's Rush
        "SIDEQUEST_DODGER",  // Violet's Rush
        "SIDEQUEST_OBSTACLE_PISTOL",  // Red's Rush
        "SIDEQUEST_SUNSET_FLIP_POWERBOMB",  // Yellow's Rush
    };

    vars.LevelIdToScene = (Func<string, string>)((string levelId) => {
        return "id/" + levelId + ".unity";
    });
    vars.IsFirstLevelId = (Func<string, bool>)((string levelId) => {
        foreach (string firstLevelId in vars.RUSH_START) {
            if (firstLevelId == levelId) {
                return true;
            }
        }
        return false;
    });
    vars.IsFirstLevelScene = (Func<string, bool>)((string levelScene) => {
        foreach (string firstLevelId in vars.RUSH_START) {
            string firstLevelScene = vars.LevelIdToScene(firstLevelId);
            if (firstLevelScene == levelScene) {
                return true;
            }
        }
        return false;
    });

    vars.includeCurrentLevel = true;  // flag which prevents doubling the time of the final rush level
}

update {

    // level ID can randomly be set to a null string for a single frame, causing false splits 
    if (string.IsNullOrEmpty(current.levelId)) {
        current.levelId = old.levelId;
    }

    // levelMicroseconds is set to 0 when loading; suppress this for a clean timer,
    // unless levelMicroseconds is actually zero. (i.e. we are on the first level)
    if (current.levelMicroseconds == 0 && !vars.IsFirstLevelScene(current.levelScene)) {
        current.levelMicroseconds = old.levelMicroseconds;
    }

    // levelMicroseconds is incremented by levelPlaythroughMicroseconds every level;
    // if levelPlaythroughMicroseconds hasn't reset yet, suppress this change.
    if (
        current.levelMicroseconds > old.levelMicroseconds &&
        current.levelPlaythroughMicroseconds > 0
    ) {
        vars.includeCurrentLevel = false;
    }

    // if we have started a new LevelPlaythrough then include the current level's timer
    if (current.levelPlaythroughMicroseconds == -1 && !vars.includeCurrentLevel) {
        vars.includeCurrentLevel = true;
    }

    if (!vars.includeCurrentLevel) {
        current.levelPlaythroughMicroseconds = 0;
    }
}

isLoading {
    return false;
}

gameTime {
    long totalMicroseconds = current.levelMicroseconds + current.levelPlaythroughMicroseconds;
    long totalMilliseconds = totalMicroseconds / 1000;
    return TimeSpan.FromMilliseconds(totalMilliseconds);
}

split {
    if (old.levelScene != current.levelScene) {
        if (settings["Rush"]) {
            return true;
        } else if (settings["New Game"]) {
            return old.levelId == "HUB_HEAVEN";
        }
    }
}


start {
    if (old.levelScene != current.levelScene) {
        if (settings["Rush"]) {
            return vars.IsFirstLevelScene(current.levelScene);
        } else if (settings["New Game"]) {
            return old.levelScene == vars.MENU_SCENE;
        }
    }
}

reset {
    if (old.levelScene != current.levelScene) {
        if (settings["Rush"]) {
            return vars.IsFirstLevelScene(current.levelScene) || current.levelScene == vars.MENU_SCENE;
        } else if (settings["New Game"]) {
            return current.levelScene == vars.MENU_SCENE;
        }
    }
}

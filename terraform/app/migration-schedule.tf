locals {
  # Migration instances must preceed IdP instances. The following are 10 minute
  # shifted versions of the default schedules. Migration instances stay up 30 minutes
  # in case a long running migration task is in the set.
  migration_rotation_schedules = {
    "nozero_norecycle" = {
      recycle_up    = []
      recycle_down  = []
      autozero_up   = []
      autozero_down = []
    }
    "nozero_normal" = {
      recycle_up    = ["50 4,10,16,22 * * *"]
      recycle_down  = ["20 5,11,17,23 * * *"]
      autozero_up   = []
      autozero_down = []
    }
    "nozero_business" = {
      recycle_up    = ["50 16 * * 1-5"]
      recycle_down  = ["20 17 * * 1-5"]
      autozero_up   = []
      autozero_down = []
    }
    "dailyzero_norecycle" = {
      recycle_up   = []
      recycle_down = []
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 16 * * *"
      ]
    }
    "dailyzero_normal" = {
      recycle_up   = ["50 10 * * 1-5"]
      recycle_down = ["20 11 * * 1-5"]
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 16 * * *"
      ]
    }
    "dailyzero_business" = {
      recycle_up   = []
      recycle_down = []
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 16 * * *"
      ]
    }
    "nightlyzero_norecycle" = {
      recycle_up   = []
      recycle_down = []
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 20 * * *"
      ]
    }
    "nightlyzero_normal" = {
      recycle_up   = ["50 10,16 * * 1-5"]
      recycle_down = ["20 11,17 * * 1-5"]
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 20 * * *"
      ]
    }
    "nightlyzero_business" = {
      recycle_up   = ["50 16 * * 1-5"]
      recycle_down = ["20 17 * * 1-5"]
      autozero_up  = ["50 4 * * *"]
      autozero_down = [
        "20 5 * * *",
        "50 20 * * *"
      ]
    }
    "weeklyzero_norecycle" = {
      recycle_up   = []
      recycle_down = []
      autozero_up  = ["50 4 * * 1"]
      autozero_down = [
        "20 5 * * 1",
        "50 16 * * 5"
      ]
    }
    "weeklyzero_normal" = {
      recycle_up = [
        "50 10,16,22 * * 1",
        "50 4,10,16,22 * * 2-4",
        "50 4,10 * * 5",
      ]
      recycle_down = [
        "20 11,17,23 * * 1",
        "20 5,11,17,23 * * 2-4",
        "20 5,11 * * 5",
      ]
      autozero_up = ["50 4 * * 1"]
      autozero_down = [
        "20 5 * * 1",
        "50 16 * * 5"
      ]
    }
    "weeklyzero_business" = {
      recycle_up   = ["50 16 * * 1-4"]
      recycle_down = ["20 17 * * 1-4"]
      autozero_up  = ["50 4 * * 1"]
      autozero_down = [
        "20 5 * * 1",
        "50 16 * * 5"
      ]
    }
  }
}

part of logic;

void unstableMove(int x, int y, int dir) {
  var cx = x;
  var cy = y;

  final self = grid.at(x, y);
  self.updated = true;
  var d = 0;

  while (true) {
    d++;
    if (d > grid.width * grid.height) return;
    cx = frontX(cx, dir);
    cy = frontY(cy, dir);
    if (!grid.inside(cx, cy)) return;

    final c = grid.at(cx, cy);

    if (c.id == "empty") {
      moveCell(x, y, cx, cy, dir);
      return;
    } else if (moveInsideOf(c, cx, cy, dir, MoveType.unkown_move)) {
      push(cx, cy, dir, 99999999999, replaceCell: self.copy);
    }
  }
}

void unstableGen(int x, int y, int dir, Cell self) {
  var cx = x;
  var cy = y;

  var d = 0;
  while (true) {
    d++;
    if (d >= grid.width * grid.height) return;
    cx = frontX(cx, dir);
    cy = frontY(cy, dir);
    if (!grid.inside(cx, cy)) return;

    final c = grid.at(cx, cy);

    if (c.id == "empty") {
      grid.set(cx, cy, self);
      return;
    } else if (moveInsideOf(c, cx, cy, dir, MoveType.unkown_move)) {
      push(cx, cy, dir, 99999999999, replaceCell: self.copy);
    }
  }
}

void doField(Cell cell, int x, int y) {
  //print("Help ${cell.lifespan}");
  //final iteration = cell.lifespan;
  final rng = Random();
  final nx = rng.nextInt(grid.width);
  final ny = rng.nextInt(grid.height);

  final randomStuff = rng.nextInt(cells.length * 200);
  final randomRot = rng.nextInt(4);

  grid.set(x, y, Cell(x, y));

  if (randomStuff >= cells.length) {
    if (randomStuff < cells.length * 2) {
      grid.set(x, y, Cell(x, y)..id = "field");
      grid.setChunk(x, y, "field");
    }
  } else {
    grid.set(
      x,
      y,
      Cell(x, y)
        ..id = cells[randomStuff]
        ..rot = randomRot
        ..lastvars.lastRot = randomRot,
    );
    grid.setChunk(x, y, cells[randomStuff]);
  }

  if (grid.at(nx, ny).id != "empty") {
    grid.addBroken(grid.at(nx, ny), nx, ny, "silent");
  }

  grid.set(nx, ny, cell.copy);
  grid.setChunk(nx, ny, cell.id);
}

class RaycastInfo {
  late Cell hitCell;
  bool successful;
  late int distance;

  RaycastInfo.successful(Cell cell, this.distance) : successful = true {
    hitCell = cell.copy;
  }

  RaycastInfo.broken() : successful = false;
}

RaycastInfo raycast(int cx, int cy, int dx, int dy) {
  var x = cx;
  var y = cy;
  var d = 0;

  while (true) {
    x += dx;
    y += dy;
    d++;
    if (d > (grid.width * grid.height)) return RaycastInfo.broken();
    if (!grid.inside(x, y)) return RaycastInfo.broken();

    final cell = grid.at(x, y);

    if (cell.id != "empty") {
      return RaycastInfo.successful(cell, d);
    }
  }
}

int clamp(int n, int minn, int maxn) => max(minn, min(n, maxn));

const particleForce = 10;
const particleForcePower = 5;
const particleMaxDist = 10;

class QuantumInteraction {
  num scale;
  bool flipWhenClose;
  num? flipDist;

  QuantumInteraction(this.scale, this.flipWhenClose, [this.flipDist]);
}

void physicsCell(int x, int y, Map<String, QuantumInteraction> interactions) {
  final c = grid.at(x, y);

  // Forces
  double vx = c.data['vel_x'] ?? 0;
  double vy = c.data['vel_y'] ?? 0;

  // Compute forces
  final offs = [1, 0, -1, 0, 0, 1, 0, -1, 1, 1, 1, -1, -1, 1, -1, -1];

  for (var i = 0; i < offs.length; i += 2) {
    final ox = offs[i];
    final oy = offs[i + 1];

    final cell = raycast(x, y, ox, oy);

    if (cell.successful) {
      if (cell.distance <= particleMaxDist) {
        if (interactions[cell.hitCell.id] != null) {
          var i = interactions[cell.hitCell.id];
          var f = particleForce * i!.scale / (pow(cell.distance, particleForcePower));
          if (i.flipWhenClose) {
            if (cell.distance < i.flipDist!.toDouble()) {
              f *= -1;
            }
          }
          vx += ox * f;
          vy += oy * f;
        }
      }
    }
  }

  // Save forces
  c.data['vel_x'] = vx;
  c.data['vel_y'] = vy;

  // Fix forces

  var mx = vx;
  var my = vy;
  if (mx < 0) mx = -1;
  if (mx > 0) mx = 1;

  if (my < 0) my = -1;
  if (my > 0) my = 1;

  // Move
  if (vx != 0 || vy != 0) {
    var cx = vx == 0 ? x : x + mx ~/ 1;
    var cy = vy == 0 ? y : y + my ~/ 1;

    if (grid.inside(cx, cy) && grid.at(cx, cy).id == "empty") {
      moveCell(x, y, cx, cy);
    } else if (grid.inside(cx, y) && grid.at(cx, y).id == "empty") {
      c.data.remove('vel_y');
      moveCell(x, y, cx, y);
    } else if (grid.inside(x, cy) && grid.at(x, cy).id == "empty") {
      c.data.remove('vel_x');
      moveCell(x, y, x, cy);
    } else {
      c.data.remove('vel_x');
      c.data.remove('vel_y');
    }
  }
}

void quantums() {
  if (grid.movable) {
    for (var rot in rotOrder) {
      grid.loopChunks(
        "unstable_mover",
        fromRot(rot),
        (cell, x, y) {
          if (cell.rot == rot) unstableMove(x, y, cell.rot);
        },
        filter: (cell, x, y) => cell.id == "unstable_mover" && cell.rot == rot && cell.updated == false,
      );
      grid.updateCell(
        (cell, x, y) {
          final bx = frontX(x, (rot + 2) % 4);
          final by = frontY(y, (rot + 2) % 4);

          if (grid.inside(bx, by)) {
            final b = grid.at(bx, by);
            unstableGen(x, y, rot, b.copy);
          }
        },
        rot,
        "unstable_gen",
      );
    }
  }

  grid.loopChunks("field", GridAlignment.topleft, doField);

  final justAttract = QuantumInteraction(1, false);
  final justRepell = QuantumInteraction(-1, false);

  // My brain hurts
  grid.updateCell(
    (cell, x, y) {
      physicsCell(x, y, {
        "proton": justAttract,
        "graviton": justAttract,
        "electron": justRepell,
      });
    },
    null,
    "electron",
  );
  grid.updateCell(
    (cell, x, y) {
      physicsCell(x, y, {
        "neutron": QuantumInteraction(5, false),
        "graviton": justAttract,
        "electron": justAttract,
        "proton": justRepell,
      });
    },
    null,
    "proton",
  );
  grid.updateCell(
    (cell, x, y) {
      physicsCell(x, y, {
        "proton": justAttract,
        "graviton": justAttract,
      });
    },
    null,
    "neutron",
  );
  grid.updateCell(
    (cell, x, y) {
      physicsCell(x, y, {
        "graviton": justAttract,
      });
    },
    null,
    "graviton",
  );

  final strangeAttract = QuantumInteraction(5, false);
  final strangeToElectron = QuantumInteraction(1, false);

  grid.updateCell(
    (cell, x, y) {
      spread(x, y, cell);
      physicsCell(x, y, {
        "graviton": strangeAttract,
        "proton": strangeAttract,
        "neutron": strangeAttract,
        "electron": strangeToElectron,
        "strangelet": strangeToElectron,
      });
    },
    null,
    "strangelet",
  );
}

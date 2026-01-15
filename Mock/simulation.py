import uvicorn
import threading
import time
import random
import os
import csv
import logging
from datetime import datetime
from typing import List, Optional, Dict
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import SQLModel, Field, Session, select, create_engine, Relationship, delete
from pydantic import BaseModel

# ==========================================
# 1. SETUP & CONFIG
# ==========================================
# สร้างโฟลเดอร์สำหรับเก็บไฟล์ Log
LOG_DIR = "logs"
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)

sqlite_file_name = "robot_arm_system.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=False)

app = FastAPI(title="Robot Arm AIoT Backend")

# อนุญาตให้ App เชื่อมต่อเข้ามาได้ (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_session():
    with Session(engine) as session:
        yield session

# ==========================================
# 2. DATABASE MODELS
# ==========================================
class TeachingPatterns(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    created_at: datetime = Field(default_factory=datetime.now)
    steps: List["PatternSteps"] = Relationship(back_populates="pattern")

class PatternSteps(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    pattern_id: Optional[int] = Field(default=None, foreign_key="teachingpatterns.id")
    sequence_order: int
    action_type: str  # 'move_joints', 'grip', 'release', 'wait'
    
    # Joint Angles
    j1: float = 0.0
    j2: float = 0.0
    j3: float = 0.0
    j4: float = 0.0
    j5: float = 0.0
    j6: float = 0.0
    
    # Gripper Settings for this step
    gripper_angle: int = 0
    wait_time: float = 0.0
    
    pattern: Optional[TeachingPatterns] = Relationship(back_populates="steps")

class RunHistory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    filename: str
    pattern_id: int
    pattern_name: str
    cycle_target: int
    cycle_completed: int = 0
    max_force: float
    status: str  # "Running", "Completed", "Stopped"
    created_at: datetime = Field(default_factory=datetime.now)

# ==========================================
# 3. GLOBAL STATE & LOGIC
# ==========================================
class RobotState(BaseModel):
    # Joints
    j1: float = 0.0
    j2: float = 0.0
    j3: float = 0.0
    j4: float = 0.0
    j5: float = 0.0
    j6: float = 0.0
    
    # Gripper Logic
    gripper_angle: int = 180    # 0=Bite, 180=Open (Example)
    is_gripping: bool = False   # True when executing Grip logic
    max_force_setting: float = 5.0 
    current_force: float = 0.0
    
    # Material Logic (Derived from MaxForce as user requested)
    detected_material: str = "Waiting..."
    confidence: float = 0.0
    
    # System Status
    mode: str = "MANUAL" # MANUAL, AUTO, TEACHING
    is_running: bool = False

current_state = RobotState()
# Removed unused legacy globals: teaching_buffer, current_editing_pattern_id, pattern_buffers 
auto_run_active = False
sequence_running = False

@app.on_event("startup")
def startup_db():
    SQLModel.metadata.create_all(engine)
    print("✅ Database initialized")
    
    # Auto-create default pattern if none exist
    with Session(engine) as session:
        existing = session.exec(select(TeachingPatterns)).first()
        if not existing:
            default_pattern = TeachingPatterns(name="Default Pattern")
            session.add(default_pattern)
            session.commit()
            session.refresh(default_pattern)
            print(f"✅ Created default pattern (ID: {default_pattern.id})")

# --- Helper Functions ---
# ... (determine_material_from_force, calculate_realistic_force, log_data_row kept as is) ...

def determine_material_from_force(max_force: float):
    if max_force >= 8.0:
        return "Metal", random.uniform(90.0, 99.9)
    elif max_force >= 4.0:
        return "Wood", random.uniform(85.0, 95.0)
    elif max_force > 0:
        return "Sponge/Soft", random.uniform(80.0, 90.0)
    else:
        return "Unknown", 0.0

def calculate_realistic_force(angle: int, max_force_setting: float, material_type: str) -> float:
    contact_ratio = 1.0 - (angle / 180.0)
    if "Metal" in material_type:
        stiffness, nonlinearity = 1.2, 2.5
    elif "Wood" in material_type:
        stiffness, nonlinearity = 1.0, 1.8
    elif "Sponge" in material_type or "Soft" in material_type:
        stiffness, nonlinearity = 0.7, 1.2
    else:
        stiffness, nonlinearity = 0.9, 1.5
    
    if angle > 135: angle_efficiency = 0.3
    elif angle > 90: angle_efficiency = 0.8
    elif angle > 45: angle_efficiency = 1.0
    else: angle_efficiency = 0.9
    
    base_force = max_force_setting * (contact_ratio ** nonlinearity)
    realistic_force = base_force * stiffness * angle_efficiency
    noise = random.uniform(-0.15, 0.15)
    realistic_force += noise
    realistic_force = max(0.0, min(realistic_force, max_force_setting * 1.1))
    if realistic_force < 0.2: realistic_force = 0.0
    return round(realistic_force, 2)

def log_data_row(filename: str, cycle: int, phase: str):
    """บันทึกข้อมูลลงไฟล์ CSV"""
    filepath = os.path.join(LOG_DIR, filename)
    file_exists = os.path.isfile(filepath)
    
    with open(filepath, mode='a', newline='') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(["Timestamp", "Cycle", "Phase", "Force_N", "Material", "Confidence", "J1", "J2", "J3"])
            
        writer.writerow([
            datetime.now().strftime("%H:%M:%S.%f")[:-3],
            cycle,
            phase,
            f"{current_state.current_force:.2f}",
            current_state.detected_material,
            f"{current_state.confidence:.1f}",
            f"{current_state.j1:.1f}",
            f"{current_state.j2:.1f}",
            f"{current_state.j3:.1f}"
        ])

# Note: move_robot_smoothly removed in favor of shared move_robot_to_target defined later

def auto_run_thread_func(pattern_id: int, cycles: int, max_force: float, filename: str):
    global current_state, auto_run_active
    
    # 1. Setup Initial State
    current_state.max_force_setting = max_force
    mat_name, conf = determine_material_from_force(max_force)
    current_state.detected_material = mat_name
    current_state.confidence = conf
    
    # Check Filename Duplication
    if not filename or filename.strip() == "":
        filename = f"run_data.csv"
    if not filename.endswith(".csv"):
        filename += ".csv"
        
    base_name, ext = os.path.splitext(filename)
    counter = 1
    while os.path.exists(os.path.join(LOG_DIR, filename)):
        filename = f"{base_name}_{counter}{ext}"
        counter += 1

    # Create History Entry
    history_id = None
    with Session(engine) as session:
        pattern = session.get(TeachingPatterns, pattern_id)
        if not pattern:
            auto_run_active = False
            return
        
        history = RunHistory(
            filename=filename,
            pattern_id=pattern_id,
            pattern_name=pattern.name,
            cycle_target=cycles,
            max_force=max_force,
            status="Running"
        )
        session.add(history)
        session.commit()
        session.refresh(history)
        history_id = history.id

    with Session(engine) as session:
        pattern = session.get(TeachingPatterns, pattern_id)
        if not pattern: 
            auto_run_active = False
            return
        
        current_state.mode = "AUTO"
        current_state.is_running = True
        steps = sorted(pattern.steps, key=lambda x: x.sequence_order)
        
        print(f"--- Starting Auto Run: {pattern.name} | File: {filename} ---")
        
        for cycle in range(cycles):
            if not auto_run_active: break
            print(f"Cycle {cycle + 1}/{cycles}")
            
            # Update Cycle Count in DB
            if history_id:
                with Session(engine) as session:
                    h = session.get(RunHistory, history_id)
                    if h:
                        h.cycle_completed = cycle + 1
                        session.add(h)
                        session.commit()
            
            for step in steps:
                if not auto_run_active: break
                
                # --- Action: MOVE ---
                if step.action_type == "move_joints":
                    # Action: MOVE
                    targets = {
                        "j1": step.j1, "j2": step.j2, "j3": step.j3,
                        "j4": step.j4, "j5": step.j5, "j6": step.j6
                    }
                    move_robot_to_target(targets)
                    log_data_row(filename, cycle+1, "Moving")
                
                # --- Action: GRIP ---
                elif step.action_type == "grip":
                    # EXACT Requirement: "Force equals Force Limit immediately, gradually rising"
                    current_state.is_gripping = True
                    target_angle = 0 # Force Close
                    start_angle = current_state.gripper_angle
                    
                    ramp_steps = 20
                    for i in range(ramp_steps):
                        if not auto_run_active: break
                        
                        progress = (i + 1) / ramp_steps
                        
                        # Visual: Close gripper
                        current_angle = int(start_angle - (start_angle - target_angle) * progress)
                        current_state.gripper_angle = max(0, current_angle)
                        
                        # Force: Linear Ramp to Max Force
                        current_state.current_force = round(max_force * progress, 2)
                        
                        time.sleep(0.05)
                        log_data_row(filename, cycle+1, "Gripping")
                        
                    # Final Hold
                    current_state.current_force = round(max_force, 2)
                    log_data_row(filename, cycle+1, "Gripping (Hold)")

                # --- Action: RELEASE ---
                elif step.action_type == "release":
                    current_state.is_gripping = False
                    current_state.current_force = 0.0
                    current_state.gripper_angle = 180 
                    time.sleep(0.5)
                    log_data_row(filename, cycle+1, "Release")
                    
                # --- Action: WAIT ---
                elif step.action_type == "wait":
                    duration = step.wait_time
                    end_time = time.time() + duration
                    while time.time() < end_time:
                        if not auto_run_active: break
                        time.sleep(0.05)
                    log_data_row(filename, cycle+1, "Waiting")

        # End Run
        current_state.mode = "MANUAL"
        current_state.is_running = False
        
        # Finalize History Status
        final_status = "Completed" if auto_run_active else "Stopped"
        if history_id:
            with Session(engine) as session:
                h = session.get(RunHistory, history_id)
                if h:
                    h.status = final_status
                    session.add(h)
                    session.commit()

        auto_run_active = False
        print("--- Auto Run Finished ---")

# ==========================================
# 4. API ENDPOINTS (For Mobile App)
# ==========================================

@app.get("/health")
def health_check():
    """Simple health endpoint used by mobile app to enforce connectivity."""
    try:
        # Quick DB check
        with Session(engine) as session:
            session.exec(select(TeachingPatterns)).first()
        return {"status": "ok", "database": "reachable"}
    except Exception as exc:  # pragma: no cover - diagnostics only
        return {"status": "degraded", "error": str(exc)}

# --- 4.1 Real-time Dashboard Data ---
@app.get("/data")
def get_sensor_data():
    """
    คืนค่า JSON สำหรับหน้า Dashboard และ Auto Run Graph
    """
    # ถ้าไม่ได้ Run อยู่ ให้ Material เป็นค่าว่างหรือตาม Force ที่ค้าง
    if not current_state.is_running and current_state.current_force < 0.5:
        mat = "Ready"
        conf = 0.0
    else:
        mat = current_state.detected_material
        conf = current_state.confidence

    return {
        "timestamp": time.time(),
        "joints": [current_state.j1, current_state.j2, current_state.j3, 
                   current_state.j4, current_state.j5, current_state.j6],
        # Individual joint values for easy access
        "j1": round(current_state.j1, 2),
        "j2": round(current_state.j2, 2),
        "j3": round(current_state.j3, 2),
        "j4": round(current_state.j4, 2),
        "j5": round(current_state.j5, 2),
        "j6": round(current_state.j6, 2),
        "force": round(current_state.current_force, 2),
        "max_force_setting": current_state.max_force_setting,
        "gripper_angle": current_state.gripper_angle,
        "material": mat,
        "confidence": round(conf, 2),
        "mode": current_state.mode,
        "is_running": current_state.is_running
    }

# --- 4.2 Manual Control ---
class ManualMoveRequest(BaseModel):
    j1: Optional[float] = None
    j2: Optional[float] = None
    j3: Optional[float] = None
    j4: Optional[float] = None
    j5: Optional[float] = None
    j6: Optional[float] = None

@app.post("/api/robot/manual-move")
def manual_move(data: ManualMoveRequest):
    if sequence_running or auto_run_active:
        raise HTTPException(status_code=423, detail="System busy (Auto Run or Sequence Active)")

    if data.j1 is not None: current_state.j1 = data.j1
    if data.j2 is not None: current_state.j2 = data.j2
    if data.j3 is not None: current_state.j3 = data.j3
    if data.j4 is not None: current_state.j4 = data.j4
    if data.j5 is not None: current_state.j5 = data.j5
    if data.j6 is not None: current_state.j6 = data.j6
    return {"status": "moved"}

class GripperControl(BaseModel):
    angle: int      # 0 - 180
    max_force: float # 0 - 10 N
    switch_on: bool # ON/OFF Switch

@app.post("/api/robot/gripper")
def control_gripper(data: GripperControl):
    """
    รับค่าจากหน้า Manual Control (Slider Max Force, Slider Angle, Switch)
    """
    if sequence_running or auto_run_active:
        raise HTTPException(status_code=423, detail="System busy (Auto Run or Sequence Active)")

    current_state.max_force_setting = data.max_force
    current_state.gripper_angle = data.angle
    
    # Logic Mock: Relaxed to < 179 degrees for easier testing
    if data.switch_on and data.angle < 179:
        current_state.is_gripping = True
        # Determine material first
        mat, conf = determine_material_from_force(data.max_force)
        current_state.detected_material = mat
        current_state.confidence = conf
        
        # Use realistic physics-based force calculation
        current_state.current_force = calculate_realistic_force(
            angle=data.angle,
            max_force_setting=data.max_force,
            material_type=mat
        )
    else:
        current_state.is_gripping = False
        current_state.current_force = 0.0
        current_state.detected_material = "Ready"
        
    return {"status": "updated", "force": current_state.current_force}

# --- 4.3 Teaching/Sync Endpoints ---
# (Simplified: Removed Legacy Buffer Endpoints)

@app.get("/api/patterns")
def get_patterns(session: Session = Depends(get_session)):
    patterns = session.exec(select(TeachingPatterns)).all()
    return [{"id": p.id, "name": p.name} for p in patterns]

@app.delete("/api/patterns/{pattern_id}")
def delete_pattern(pattern_id: int, session: Session = Depends(get_session)):
    pattern = session.get(TeachingPatterns, pattern_id)
    if not pattern:
        return {"error": "Not found"}
    
    # Delete associated steps
    session.exec(delete(PatternSteps).where(PatternSteps.pattern_id == pattern_id))
    session.delete(pattern)
    session.commit()
    
    return {"message": "Deleted"}

# --- 4.3.1 Full Sync Endpoints (SQLite ↔ Backend) ---
class SyncPatternStep(BaseModel):
    step_order: int
    action_type: str
    params: dict

class SyncPattern(BaseModel):
    id: Optional[int] = None
    name: str
    description: Optional[str] = None
    steps: List[SyncPatternStep] = []

class SyncPatternsRequest(BaseModel):
    patterns: List[SyncPattern]

@app.get("/api/sync/patterns")
def sync_patterns_pull(session: Session = Depends(get_session)):
    patterns = session.exec(select(TeachingPatterns)).all()
    response = []
    for pat in patterns:
        steps = session.exec(
            select(PatternSteps)
            .where(PatternSteps.pattern_id == pat.id)
            .order_by(PatternSteps.sequence_order)
        ).all()

        step_payload = []
        for s in steps:
            params = {
                "j1": s.j1,
                "j2": s.j2,
                "j3": s.j3,
                "j4": s.j4,
                "j5": s.j5,
                "j6": s.j6,
                "gripper_angle": s.gripper_angle,
                "angle": s.gripper_angle,
                "wait_time": s.wait_time,
                "duration": s.wait_time,
            }
            step_payload.append({
                "step_order": max(0, s.sequence_order - 1),
                "action_type": s.action_type,
                "params": params,
            })

        response.append({
            "id": pat.id,
            "name": pat.name,
            "description": None,
            "created_at": pat.created_at.isoformat() if pat.created_at else None,
            "updated_at": pat.created_at.isoformat() if pat.created_at else None,
            "steps": step_payload,
        })

    return {"patterns": response}


@app.post("/api/sync/patterns")
def sync_patterns_push(payload: SyncPatternsRequest, session: Session = Depends(get_session)):
    synced = 0
    incoming_ids = set()

    for pat_data in payload.patterns:
        # 1) Find existing by ID, fallback to name
        pat = session.get(TeachingPatterns, pat_data.id) if pat_data.id else None
        if not pat:
            pat = session.exec(select(TeachingPatterns).where(TeachingPatterns.name == pat_data.name)).first()

        # 2) Create if missing
        if not pat:
            pat = TeachingPatterns(name=pat_data.name)
            session.add(pat)
            session.commit()
            session.refresh(pat)
        else:
            pat.name = pat_data.name

        if pat.id is not None:
            incoming_ids.add(pat.id)

        # 3) Replace steps
        session.exec(delete(PatternSteps).where(PatternSteps.pattern_id == pat.id))

        ordered_steps = sorted(pat_data.steps, key=lambda s: s.step_order)
        
        for step in ordered_steps:
            params = step.params or {}

            j1 = float(params.get("j1", 0.0) or 0.0)
            j2 = float(params.get("j2", 0.0) or 0.0)
            j3 = float(params.get("j3", 0.0) or 0.0)
            j4 = float(params.get("j4", 0.0) or 0.0)
            j5 = float(params.get("j5", 0.0) or 0.0)
            j6 = float(params.get("j6", 0.0) or 0.0)
            wait_time = float(params.get("duration", params.get("wait_time", 0.0)) or 0.0)
            gripper_angle = int(params.get("angle", params.get("gripper_angle", 0)) or 0)

            session.add(PatternSteps(
                pattern_id=pat.id,
                sequence_order=step.step_order + 1,
                action_type=step.action_type,
                j1=j1, j2=j2, j3=j3, j4=j4, j5=j5, j6=j6,
                gripper_angle=gripper_angle,
                wait_time=wait_time,
            ))

        session.commit()
        synced += 1

    # 4) Delete patterns that are no longer present in payload
    existing_ids = {p.id for p in session.exec(select(TeachingPatterns)).all() if p.id is not None}
    to_delete = existing_ids - incoming_ids
    for pid in to_delete:
        session.exec(delete(PatternSteps).where(PatternSteps.pattern_id == pid))
        session.exec(delete(TeachingPatterns).where(TeachingPatterns.id == pid))
    session.commit()

    return {"message": "Synced", "count": synced, "deleted": len(to_delete)}

# --- 4.4 Execute Sequence (backend-driven play) ---
class SequenceStep(BaseModel):
    step_order: int
    action_type: str
    params: dict = {}

class ExecuteSequenceRequest(BaseModel):
    steps: List[SequenceStep]
    max_force: float
    gripper_angle: float
    is_on: bool
    pattern_name: Optional[str] = None

# Shared Helper for Interpolation
def move_robot_to_target(targets: dict, duration_override: float = None):
    """
    Shared function to move robot joints smoothly.
    Respects global stop flags (auto_run_active, sequence_running).
    """
    def lerp(a, b, t): return a + (b - a) * t

    start_vals = {
        "j1": current_state.j1, "j2": current_state.j2, "j3": current_state.j3,
        "j4": current_state.j4, "j5": current_state.j5, "j6": current_state.j6
    }
    
    # Check what keys are present, default to current
    safe_targets = {
        "j1": float(targets.get("j1", current_state.j1)),
        "j2": float(targets.get("j2", current_state.j2)),
        "j3": float(targets.get("j3", current_state.j3)),
        "j4": float(targets.get("j4", current_state.j4)),
        "j5": float(targets.get("j5", current_state.j5)),
        "j6": float(targets.get("j6", current_state.j6)),
    }

    # Interpolation settings    
    steps = 60
    interval = 0.04 # 60 * 0.04 = 2.4 seconds approx movement time
    
    for i in range(steps):
        # Check Stop Flags
        if not auto_run_active and not sequence_running:
            break
            
        t = (i + 1) / steps
        current_state.j1 = lerp(start_vals["j1"], safe_targets["j1"], t)
        current_state.j2 = lerp(start_vals["j2"], safe_targets["j2"], t)
        current_state.j3 = lerp(start_vals["j3"], safe_targets["j3"], t)
        current_state.j4 = lerp(start_vals["j4"], safe_targets["j4"], t)
        current_state.j5 = lerp(start_vals["j5"], safe_targets["j5"], t)
        current_state.j6 = lerp(start_vals["j6"], safe_targets["j6"], t)
        time.sleep(interval)

@app.post("/api/teach/execute-sequence")
def execute_sequence(req: ExecuteSequenceRequest):
    global sequence_running
    if auto_run_active:
         return {"error": "System busy (Auto Run Active)"}
    if sequence_running:
         return {"error": "System busy (Sequence Active)"}
         
    # Run in background thread
    t = threading.Thread(target=execute_sequence_worker, args=(req,))
    t.start()
    return {"message": "Sequence started"}

def execute_sequence_worker(req: ExecuteSequenceRequest):
    global sequence_running
    sequence_running = True

    print(f"🎬 Execute sequence: {req.pattern_name}, steps={len(req.steps)}")
    current_state.mode = "TEACHING"
    current_state.is_running = req.is_on
    current_state.max_force_setting = req.max_force
    current_state.gripper_angle = int(req.gripper_angle)

    ordered_steps = sorted(req.steps, key=lambda s: s.step_order)

    for step in ordered_steps:
        if not sequence_running: break
        
        action = step.action_type.lower()
        params = step.params or {}

        if action == "move_joints":
            # Use shared helper
            print(f"  📍 MOVE_JOINTS: {params}")
            move_robot_to_target(params)
            
        elif action == "grip":
            # Play Sequence Mode: Uses realistic physics (keeps gripper angle logic)
            print(f"  🤏 GRIP (Physics)")
            angle = int(params.get("angle", params.get("gripper_angle", current_state.gripper_angle)))
            current_state.gripper_angle = angle
            current_state.is_gripping = req.is_on
            
            mat, conf = determine_material_from_force(req.max_force)
            current_state.detected_material = mat
            current_state.confidence = conf
            
            # Physics Force
            current_state.current_force = calculate_realistic_force(
                angle=angle,
                max_force_setting=req.max_force,
                material_type=mat,
            )
            time.sleep(0.5)

        elif action == "release":
            print(f"  👐 RELEASE")
            current_state.gripper_angle = 180
            current_state.is_gripping = False
            current_state.current_force = 0.0
            time.sleep(0.5)
            
        elif action == "wait":
            duration = float(params.get("duration", params.get("wait_time", 1.0)))
            print(f"  ⏱️  WAIT: {duration}s")
            end_time = time.time() + duration
            while time.time() < end_time:
                if not sequence_running: break
                time.sleep(0.1)

    sequence_running = False
    current_state.mode = "MANUAL"
    current_state.is_running = False
    print("✅ Sequence finished")

@app.post("/api/teach/stop")
def stop_sequence():
    global sequence_running, auto_run_active
    sequence_running = False
    auto_run_active = False # Kill both just in case
    current_state.is_running = False
    current_state.mode = "MANUAL"
    return {"message": "Stopped"}

# --- 4.4 Auto Run & Logging ---
class AutoRunRequest(BaseModel):
    pattern_id: int
    cycles: int
    max_force: float
    filename: str  # รับชื่อไฟล์จาก App

@app.post("/auto-run/start")
def start_auto_run(req: AutoRunRequest):
    global auto_run_active
    if auto_run_active: return {"error": "System busy (Auto Run Active)"}
    if sequence_running: return {"error": "System busy (Sequence Active)"}
    
    auto_run_active = True
    t = threading.Thread(
        target=auto_run_thread_func, 
        args=(req.pattern_id, req.cycles, req.max_force, req.filename)
    )
    t.start()
    return {"status": "Started", "file": req.filename}

@app.post("/auto-run/stop")
def stop_auto_run():
    global auto_run_active
    auto_run_active = False
    return {"status": "Stopping..."}

@app.get("/api/logs/download/{filename}")
def download_log(filename: str):
    """ดาวน์โหลดไฟล์ Log CSV"""
    file_path = os.path.join(LOG_DIR, filename)
    if not filename.endswith(".csv"):
        file_path += ".csv"
        
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type='text/csv', filename=filename)
    else:
        raise HTTPException(status_code=404, detail="File not found")

# --- 4.5 Auto Run History ---
@app.get("/api/history")
def get_run_history(session: Session = Depends(get_session)):
    """Get list of past auto runs"""
    history = session.exec(select(RunHistory).order_by(RunHistory.created_at.desc())).all()
    return history

@app.delete("/api/history/{history_id}")
def delete_run_history(history_id: int, session: Session = Depends(get_session)):
    history = session.get(RunHistory, history_id)
    if not history:
        raise HTTPException(status_code=404, detail="History not found")
    
    # Try to delete the actual file
    file_path = os.path.join(LOG_DIR, history.filename)
    if os.path.exists(file_path):
        try:
            os.remove(file_path)
        except Exception as e:
            print(f"Error deleting file {file_path}: {e}")
            
    session.delete(history)
    session.commit()
    return {"message": "Deleted"}

# --- 4.6 Web Simulation UI (Optional) ---
@app.get("/", response_class=HTMLResponse)
def ui():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Robot Control Panel</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 20px;
                margin: 0;
            }
            .container {
                max-width: 800px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                padding: 30px;
                box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            }
            h1 {
                color: #667eea;
                text-align: center;
                margin-top: 0;
            }
            .status {
                background: #f0f4f8;
                padding: 15px;
                border-radius: 10px;
                margin-bottom: 20px;
                font-family: monospace;
                font-size: 12px;
            }
            .joint-control {
                margin: 20px 0;
                padding: 15px;
                background: #f8f9fa;
                border-radius: 10px;
                display: grid;
                grid-template-columns: 2fr 1fr;
                gap: 20px;
                align-items: center;
            }
            .joint-slider-section {
                display: flex;
                flex-direction: column;
            }
            .joint-label {
                font-weight: 600;
                color: #333;
                margin-bottom: 8px;
                font-size: 14px;
            }
            .joint-display-section {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .joint-display {
                background: #667eea;
                color: white;
                padding: 12px 24px;
                border-radius: 8px;
                text-align: center;
                font-weight: bold;
                font-size: 24px;
                box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
                min-width: 100px;
            }
            .display-label {
                font-size: 11px;
                color: #888;
                margin-bottom: 6px;
                text-transform: uppercase;
                letter-spacing: 1px;
            }
            .slider-label {
                font-size: 12px;
                color: #666;
                margin-top: 4px;
            }
            input[type="range"] {
                width: 100%;
                height: 8px;
                border-radius: 5px;
                background: #d3d3d3;
                outline: none;
                -webkit-appearance: none;
            }
            input[type="range"]::-webkit-slider-thumb {
                -webkit-appearance: none;
                appearance: none;
                width: 20px;
                height: 20px;
                border-radius: 50%;
                background: #667eea;
                cursor: pointer;
            }
            input[type="range"]::-moz-range-thumb {
                width: 20px;
                height: 20px;
                border-radius: 50%;
                background: #667eea;
                cursor: pointer;
            }
            .gripper-control {
                background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
                color: white;
                padding: 20px;
                border-radius: 10px;
                margin-top: 20px;
            }
            .btn {
                background: #00c853;
                color: white;
                border: none;
                padding: 12px 30px;
                border-radius: 8px;
                cursor: pointer;
                font-size: 16px;
                font-weight: bold;
                margin: 10px 5px;
            }
            .btn:hover {
                background: #00e676;
            }
            .btn-danger {
                background: #ff5252;
            }
            .btn-danger:hover {
                background: #ff6e6e;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🤖 Robot Gripper Control Panel</h1>
            
            <div class="status" id="status">Loading...</div>
            
            <h3>Joint Controls</h3>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 1 (Base Rotation)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j1" min="-180" max="180" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j1-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j1-display">0°</div>
                </div>
            </div>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 2 (Shoulder)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j2" min="-90" max="90" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j2-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j2-display">0°</div>
                </div>
            </div>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 3 (Elbow)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j3" min="-90" max="90" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j3-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j3-display">0°</div>
                </div>
            </div>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 4 (Wrist Roll)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j4" min="-180" max="180" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j4-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j4-display">0°</div>
                </div>
            </div>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 5 (Wrist Pitch)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j5" min="-90" max="90" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j5-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j5-display">0°</div>
                </div>
            </div>
            
            <div class="joint-control">
                <div class="joint-slider-section">
                    <div class="joint-label">Joint 6 (Wrist Yaw)</div>
                    <div class="slider-label">Manual Control:</div>
                    <input type="range" id="j6" min="-180" max="180" value="0" step="1">
                    <div style="text-align: right; font-size: 12px; color: #999; margin-top: 4px;">
                        <span id="j6-slider-val">0°</span>
                    </div>
                </div>
                <div class="joint-display-section">
                    <div class="display-label">Position</div>
                    <div class="joint-display" id="j6-display">0°</div>
                </div>
            </div>
            
            <div style="text-align: center; margin-top: 20px;">
                <button class="btn" onclick="sendAll()">📤 Send Joints</button>
                <button class="btn btn-danger" onclick="resetAll()">🔄 Reset All</button>
            </div>
        </div>
        
        <script>
            let sendTimeout = null;
            
            // Update slider values when sliders move
            ['j1', 'j2', 'j3', 'j4', 'j5', 'j6'].forEach(id => {
                const slider = document.getElementById(id);
                const sliderVal = document.getElementById(id + '-slider-val');
                slider.addEventListener('input', (e) => {
                    sliderVal.textContent = e.target.value + '°';
                    
                    // Auto-send after 300ms of no changes (debounce)
                    clearTimeout(sendTimeout);
                    sendTimeout = setTimeout(() => {
                        sendAll(true); // true = silent mode (no alert)
                    }, 300);
                });
            });
            
            // Send all joints to backend
            async function sendAll(silent = false) {
                const data = {
                    j1: parseFloat(document.getElementById('j1').value),
                    j2: parseFloat(document.getElementById('j2').value),
                    j3: parseFloat(document.getElementById('j3').value),
                    j4: parseFloat(document.getElementById('j4').value),
                    j5: parseFloat(document.getElementById('j5').value),
                    j6: parseFloat(document.getElementById('j6').value)
                };
                
                try {
                    const res = await fetch('/api/robot/manual-move', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify(data)
                    });
                    if (res.ok && !silent) {
                        alert('✅ Joints updated!');
                    }
                } catch (e) {
                    if (!silent) {
                        alert('❌ Error: ' + e.message);
                    }
                }
            }
            
            // Reset all to zero
            function resetAll() {
                ['j1', 'j2', 'j3', 'j4', 'j5', 'j6'].forEach(id => {
                    document.getElementById(id).value = 0;
                    document.getElementById(id + '-slider-val').textContent = '0°';
                });
            }
            
            // Status and Joint update - synced with backend
            setInterval(async() => {
                try {
                    const res = await fetch('/data');
                    const data = await res.json();
                    
                    // Update status display
                    document.getElementById('status').innerHTML = 
                        `<strong>Force:</strong> ${data.force} N | ` +
                        `<strong>Material:</strong> ${data.material} (${data.confidence}%) | ` +
                        `<strong>Gripper:</strong> ${data.gripper_angle}° | ` +
                        `<strong>Mode:</strong> ${data.mode}`;
                    
                    // Always update joint displays from backend
                    updateJointDisplay('j1', data.j1);
                    updateJointDisplay('j2', data.j2);
                    updateJointDisplay('j3', data.j3);
                    updateJointDisplay('j4', data.j4);
                    updateJointDisplay('j5', data.j5);
                    updateJointDisplay('j6', data.j6);
                } catch (e) {
                    document.getElementById('status').textContent = 'Connection Error';
                }
            }, 300); // Faster polling for smooth animation during sequence playback
            
            // Helper to update joint display (real robot position from backend)
            function updateJointDisplay(jointId, value) {
                const display = document.getElementById(jointId + '-display');
                if (display) {
                    display.textContent = Math.round(value) + '°';
                }
            }
        </script>
    </body>
    </html>
    """

# Custom logging filter to suppress /data endpoint logs
class EndpointFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        # Suppress logs for /data endpoint (too frequent)
        return record.getMessage().find('GET /data') == -1

# Apply filter to uvicorn access logger
logging.getLogger("uvicorn.access").addFilter(EndpointFilter())

if __name__ == "__main__":
    print("🚀 Starting Robot Gripper Backend Server...")
    print("📡 Polling endpoints: /data (suppressed in logs)")
    print("🌐 Web UI: http://localhost:8000")
    uvicorn.run(app, host="0.0.0.0", port=8000)
"""
Generate ER Diagram XML for Draw.io from SQLite database
Usage: python generate_er_diagram.py
Output: er_diagram.xml (can be imported to draw.io)
"""

import sqlite3
import xml.etree.ElementTree as ET
from typing import List, Tuple, Dict

class ERDiagramGenerator:
    def __init__(self, db_path: str = "robot_arm_system.db"):
        self.db_path = db_path
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        
    def get_tables(self) -> List[str]:
        """Get all table names from database"""
        self.cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        return [row[0] for row in self.cursor.fetchall()]
    
    def get_columns(self, table_name: str) -> List[Dict]:
        """Get column info for a table"""
        self.cursor.execute(f"PRAGMA table_info({table_name})")
        columns = []
        for row in self.cursor.fetchall():
            columns.append({
                'name': row[1],
                'type': row[2],
                'notnull': row[3],
                'default': row[4],
                'pk': row[5]
            })
        return columns
    
    def get_foreign_keys(self, table_name: str) -> List[Dict]:
        """Get foreign key info for a table"""
        self.cursor.execute(f"PRAGMA foreign_key_list({table_name})")
        fks = []
        for row in self.cursor.fetchall():
            fks.append({
                'from_col': row[3],
                'to_table': row[2],
                'to_col': row[4]
            })
        return fks
    
    def generate_drawio_xml(self) -> str:
        """Generate Draw.io compatible XML"""
        tables = self.get_tables()
        
        # Create root elements
        mxfile = ET.Element('mxfile', {
            'host': 'app.diagrams.net',
            'modified': '2026-01-17',
            'agent': 'Mozilla/5.0',
            'version': '20.8.0',
            'type': 'device'
        })
        
        diagram = ET.SubElement(mxfile, 'diagram', {'name': 'ER Diagram', 'id': 'ER'})
        mxGraphModel = ET.SubElement(diagram, 'mxGraphModel', {
            'dx': '1200',
            'dy': '800',
            'grid': '1',
            'gridSize': '10',
            'guides': '1',
            'tooltips': '1',
            'connect': '1',
            'arrows': '1',
            'fold': '1',
            'page': '1',
            'pageScale': '1',
            'pageWidth': '850',
            'pageHeight': '1100',
            'background': '#ffffff',
            'math': '0',
            'shadow': '0'
        })
        
        root = ET.SubElement(mxGraphModel, 'root')
        
        # Add default mxCell styles
        ET.SubElement(root, 'mxCell', {'id': '0'})
        ET.SubElement(root, 'mxCell', {'id': '1', 'parent': '0'})
        
        # Position tables horizontally
        x_positions = {table: 50 + i * 350 for i, table in enumerate(tables)}
        y_pos = 50
        
        table_ids = {}
        cell_id_counter = 2
        
        # Create table cells
        for table in tables:
            table_ids[table] = str(cell_id_counter)
            columns = self.get_columns(table)
            
            # Table header
            header_height = 30
            row_height = 25
            total_height = header_height + len(columns) * row_height
            
            x = x_positions[table]
            
            # Table background (grouping container)
            table_cell = ET.SubElement(root, 'mxCell', {
                'id': str(cell_id_counter),
                'value': table.upper(),
                'style': 'swimlane;fontStyle=1;align=center;verticalAlign=top;childLayout=stackLayout;horizontal=1;startSize=30;horizontalStack=0;resizeParent=1;resizeParentMax=0;resizeLast=0;collapsible=1;marginBottom=0;',
                'vertex': '1',
                'parent': '1'
            })
            ET.SubElement(table_cell, 'mxGeometry', {
                'x': str(x),
                'y': str(y_pos),
                'width': '300',
                'height': str(total_height),
                'as': 'geometry'
            })
            
            cell_id_counter += 1
            
            # Column rows
            for col_idx, col in enumerate(columns):
                col_y = header_height + col_idx * row_height
                
                # Format column display
                pk_marker = "🔑 " if col['pk'] else ""
                fk_marker = "🔗 " if self.is_foreign_key(table, col['name']) else ""
                null_marker = "" if col['notnull'] else " (NULL)"
                
                col_text = f"{pk_marker}{fk_marker}{col['name']}: {col['type']}{null_marker}"
                
                col_cell = ET.SubElement(root, 'mxCell', {
                    'id': str(cell_id_counter),
                    'value': col_text,
                    'style': 'text;strokeColor=none;fillColor=none;align=left;verticalAlign=top;spacingLeft=4;spacingRight=4;overflow=hidden;rotatable=0;points=[[0,0.5],[1,0.5]];portConstraint=eastwest;',
                    'vertex': '1',
                    'parent': str(cell_id_counter - 1)
                })
                ET.SubElement(col_cell, 'mxGeometry', {
                    'y': str(col_y),
                    'width': '300',
                    'height': str(row_height),
                    'as': 'geometry'
                })
                
                cell_id_counter += 1
        
        # Create relationships
        for table in tables:
            fks = self.get_foreign_keys(table)
            for fk in fks:
                from_table = table
                to_table = fk['to_table']
                
                if to_table not in table_ids:
                    continue
                
                from_x = x_positions[from_table] + 150
                from_y = y_pos + 50
                to_x = x_positions[to_table] + 150
                to_y = y_pos + 50
                
                # Connection
                connector = ET.SubElement(root, 'mxCell', {
                    'id': str(cell_id_counter),
                    'value': f"{fk['from_col']} → {fk['to_col']}",
                    'style': 'edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;endArrow=ERoneToMany;startArrow=ERmandOne;',
                    'edge': '1',
                    'parent': '1',
                    'source': table_ids[from_table],
                    'target': table_ids[to_table]
                })
                ET.SubElement(connector, 'mxGeometry', {'relative': '1', 'as': 'geometry'})
                
                cell_id_counter += 1
        
        return ET.tostring(root.getparent(), encoding='unicode')
    
    def is_foreign_key(self, table: str, column: str) -> bool:
        """Check if a column is a foreign key"""
        fks = self.get_foreign_keys(table)
        return any(fk['from_col'] == column for fk in fks)
    
    def generate_and_save(self, output_file: str = "er_diagram.xml"):
        """Generate XML and save to file"""
        xml_content = self.generate_drawio_xml()
        
        # Pretty format
        dom = ET.fromstring(xml_content)
        formatted_xml = ET.tostring(dom, encoding='unicode')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n')
            f.write(formatted_xml)
        
        print(f"✅ ER Diagram generated: {output_file}")
        print(f"📝 Steps to import to Draw.io:")
        print(f"   1. Go to https://draw.io/")
        print(f"   2. Click 'File' → 'Open' or 'New'")
        print(f"   3. Click 'File' → 'Import From' → 'Device'")
        print(f"   4. Select '{output_file}'")
        print(f"   5. Or drag and drop the file to draw.io")

# Version for Flutter database
class FlutterERDiagramGenerator(ERDiagramGenerator):
    """Generate ER Diagram for Flutter database"""
    def __init__(self, db_path: str = None):
        if db_path is None:
            # Adjust path if needed
            import os
            home = os.path.expanduser("~")
            flutter_db = os.path.join(
                home, 
                'AppData', 'Local', 'Temp',
                'robotic_gripper.db'
            )
            db_path = flutter_db
        super().__init__(db_path)

def generate_all_diagrams():
    """Generate diagrams for both Mock and Flutter databases"""
    
    # Mock database
    print("\n" + "="*60)
    print("Generating ER Diagram for Mock (Backend)")
    print("="*60)
    try:
        gen_mock = ERDiagramGenerator("robot_arm_system.db")
        gen_mock.generate_and_save("er_diagram_mock.xml")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Create a summary document
    create_summary_document()

def create_summary_document():
    """Create a detailed schema summary"""
    gen = ERDiagramGenerator("robot_arm_system.db")
    
    with open("DATABASE_SCHEMA.md", 'w', encoding='utf-8') as f:
        f.write("# Database Schema Documentation\n\n")
        f.write("## Mock Database (Backend)\n\n")
        
        for table in gen.get_tables():
            columns = gen.get_columns(table)
            fks = gen.get_foreign_keys(table)
            
            f.write(f"### Table: `{table}`\n\n")
            f.write("| Column | Type | PK | FK | Nullable |\n")
            f.write("|--------|------|----|----|----------|\n")
            
            for col in columns:
                is_fk = "✓" if gen.is_foreign_key(table, col['name']) else ""
                is_pk = "✓" if col['pk'] else ""
                nullable = "✗" if col['notnull'] else "✓"
                f.write(f"| {col['name']} | {col['type']} | {is_pk} | {is_fk} | {nullable} |\n")
            
            if fks:
                f.write("\n**Foreign Keys:**\n")
                for fk in fks:
                    f.write(f"- `{fk['from_col']}` → `{fk['to_table']}.{fk['to_col']}`\n")
            
            f.write("\n")
    
    print(f"✅ Schema documentation created: DATABASE_SCHEMA.md")

if __name__ == "__main__":
    generate_all_diagrams()

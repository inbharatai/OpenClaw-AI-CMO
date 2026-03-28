```
===FILE: anganwadi-tracker.html===
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Anganwadi Tracker</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 0; background: #f5f5f5; }
        header { background: #1a73e8; color: white; padding: 1rem; text-align: center; }
        header h1 { margin: 0; font-size: 1.5rem; }
        main { padding: 1rem; max-width: 600px; margin: auto; }
        form { background: white; padding: 1rem; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        form input, form select { width: 100%; padding: 0.5rem; margin: 0.5rem 0 1rem; border: 1px solid #ccc; border-radius: 4px; }
        form button { background: #34a853; color: white; border: none; padding: 0.6rem 1rem; border-radius: 4px; cursor: pointer; }
        form button:hover { background: #289646; }
        #entries { margin-top: 2rem; }
        .entry { background: #fff; padding: 1rem; margin-bottom: 1rem; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        footer { text-align: center; padding: 1rem; background: #f5f5f5; margin-top: 2rem; }
        footer p { color: #666; font-size: 0.9rem; }
    </style>
</head>
<body>
    <header>
        <h1>Anganwadi Worker Tracker</h1>
        <p>Track attendance and child nutrition data</p>
    </header>
    <main>
        <form id="trackerForm">
            <label for="worker">Worker Name:</label>
            <input type="text" id="worker" required>
            
            <label for="date">Date:</label>
            <input type="date" id="date" required>
            
            <label for="children">Children Attended:</label>
            <input type="number" id="children" min="0" required>
            
            <label for="meals">Meals Provided:</label>
            <select id="meals" required>
                <option value="0">0</option>
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
            </select>
            
            <button type="submit">Record Entry</button>
        </form>
        <div id="entries"></div>
    </main>
    <footer>
        <p>Powered by InBharat AI — AI for India</p>
    </footer>
    <script>
        // Sample data for demo
        const sampleData = [
            { worker: "Ramesh", date: "2026-03-25", children: 20, meals: 2 },
            { worker: "Sunita", date: "2026-03-24", children: 18, meals: 3 }
        ];

        // Load data from localStorage or use sample
        let entries = JSON.parse(localStorage.getItem('anganwadiEntries') || JSON.stringify(sampleData));

        // Display entries
        function renderEntries() {
            const container = document.getElementById('entries');
            container.innerHTML = '';
            entries.forEach((entry, index) => {
                const div = document.createElement('div');
                div.className = 'entry';
                div.innerHTML = `
                    <strong>${entry.worker}</strong> - ${entry.date}
                    <p>Children: ${entry.children} | Meals: ${entry.meals}</p>
                    <button onclick="deleteEntry(${index})">Delete</button>
                `;
                container.appendChild(div);
            });
        }

        // Handle form submission
        document.getElementById('trackerForm').addEventListener('submit', function(e) {
            e.preventDefault();
            const worker = document.getElementById('worker').value.trim();
            const date = document.getElementById('date').value;
            const children = parseInt(document.getElementById('children').value);
            const meals = parseInt(document.getElementById('meals').value);

            if (!worker || !date || isNaN(children) || isNaN(meals)) {
                alert('Please fill all fields correctly');
                return;
            }

            entries.push({ worker, date, children, meals });
            localStorage.setItem('anganwadiEntries', JSON.stringify(entries));
            renderEntries();
            this.reset();
        });

        // Delete entry
        function deleteEntry(index) {
            if (confirm('Are you sure you want to delete this entry?')) {
                entries.splice(index, 1);
                localStorage.setItem('anganwadiEntries', JSON.stringify(entries));
                renderEntries();
            }
        }

        // Initial render
        renderEntries();
    </script>
</body>
</html>
===END===
```

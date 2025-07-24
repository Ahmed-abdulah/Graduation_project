#!/usr/bin/env python3
"""
Analyze and visualize the disease test results
"""

import os
import json
import sys
import matplotlib.pyplot as plt
import numpy as np
from pathlib import Path

def load_test_results(results_dir="test_results"):
    """Load all test results from the results directory"""
    # Check if summary file exists
    summary_path = os.path.join(results_dir, "overall_summary.json")
    if os.path.exists(summary_path):
        with open(summary_path, 'r') as f:
            summary = json.load(f)
    else:
        print(f"Summary file not found: {summary_path}")
        summary = None
    
    # Load individual disease results
    disease_results = {}
    for result_file in Path(results_dir).glob("*_results.json"):
        disease_name = result_file.stem.split('_')[0]
        with open(result_file, 'r') as f:
            disease_results[disease_name] = json.load(f)
    
    return summary, disease_results

def generate_accuracy_report(summary, disease_results, output_dir="test_reports"):
    """Generate accuracy report for all diseases"""
    os.makedirs(output_dir, exist_ok=True)
    
    # Create report file
    report_path = os.path.join(output_dir, "accuracy_report.txt")
    with open(report_path, 'w') as f:
        f.write("🏥 DISEASE DETECTION ACCURACY REPORT\n")
        f.write("=" * 50 + "\n\n")
        
        if summary:
            f.write(f"Overall Accuracy: {summary['accuracy']:.2%} ({summary['total_correct']}/{summary['total_tests']})\n\n")
            
            f.write("Results by Disease:\n")
            f.write("-" * 50 + "\n")
            f.write(f"{'Disease':<15} | {'Accuracy':<10} | {'Correct/Total':<15} | {'Notes':<20}\n")
            f.write("-" * 50 + "\n")
            
            # Sort diseases by accuracy
            sorted_diseases = sorted(
                summary['results_by_disease'].items(),
                key=lambda x: x[1]['accuracy'],
                reverse=True
            )
            
            for disease, stats in sorted_diseases:
                accuracy = stats['accuracy']
                correct = stats['correct']
                total = stats['total']
                
                # Add notes based on accuracy
                if accuracy >= 0.9:
                    notes = "Excellent"
                elif accuracy >= 0.7:
                    notes = "Good"
                elif accuracy >= 0.5:
                    notes = "Fair"
                else:
                    notes = "Poor - Needs improvement"
                
                f.write(f"{disease:<15} | {accuracy:.2%}     | {correct}/{total:<13} | {notes:<20}\n")
        
        else:
            f.write("No summary data available.\n\n")
            
            # Calculate basic stats from disease_results
            if disease_results:
                f.write("Results by Disease (calculated from individual results):\n")
                f.write("-" * 50 + "\n")
                f.write(f"{'Disease':<15} | {'Accuracy':<10} | {'Correct/Total':<15} | {'Notes':<20}\n")
                f.write("-" * 50 + "\n")
                
                for disease, results in disease_results.items():
                    correct = sum(1 for r in results if r.get('correct_detection', False))
                    total = len(results)
                    accuracy = correct / total if total > 0 else 0
                    
                    # Add notes based on accuracy
                    if accuracy >= 0.9:
                        notes = "Excellent"
                    elif accuracy >= 0.7:
                        notes = "Good"
                    elif accuracy >= 0.5:
                        notes = "Fair"
                    else:
                        notes = "Poor - Needs improvement"
                    
                    f.write(f"{disease:<15} | {accuracy:.2%}     | {correct}/{total:<13} | {notes:<20}\n")
        
        f.write("\n\n")
        f.write("Detailed Analysis:\n")
        f.write("=" * 50 + "\n\n")
        
        # Add detailed analysis for each disease
        for disease, results in disease_results.items():
            f.write(f"Disease: {disease.upper()}\n")
            f.write("-" * 50 + "\n")
            
            for i, result in enumerate(results):
                f.write(f"Test Case {i+1}: {result['test_file']}\n")
                f.write(f"  Expected: {result['expected']}\n")
                f.write(f"  Detected: {result['detected']}\n")
                f.write(f"  Confidence: {result['confidence']:.2%}\n")
                f.write(f"  Correct: {'✓' if result.get('correct_detection', False) else '✗'}\n")
                f.write("\n")
            
            f.write("\n")
    
    print(f"✓ Accuracy report generated: {report_path}")
    return report_path

def generate_visualizations(summary, disease_results, output_dir="test_reports"):
    """Generate visualizations of test results"""
    os.makedirs(output_dir, exist_ok=True)
    
    # 1. Overall accuracy bar chart
    if summary:
        plt.figure(figsize=(12, 6))
        
        diseases = []
        accuracies = []
        
        for disease, stats in summary['results_by_disease'].items():
            diseases.append(disease)
            accuracies.append(stats['accuracy'])
        
        # Sort by accuracy
        sorted_indices = np.argsort(accuracies)[::-1]
        diseases = [diseases[i] for i in sorted_indices]
        accuracies = [accuracies[i] for i in sorted_indices]
        
        # Create bar chart
        bars = plt.bar(diseases, accuracies)
        
        # Color bars based on accuracy
        for i, bar in enumerate(bars):
            if accuracies[i] >= 0.9:
                bar.set_color('green')
            elif accuracies[i] >= 0.7:
                bar.set_color('yellowgreen')
            elif accuracies[i] >= 0.5:
                bar.set_color('orange')
            else:
                bar.set_color('red')
        
        plt.axhline(y=0.7, color='gray', linestyle='--', alpha=0.7)
        plt.text(0, 0.71, 'Acceptable threshold (70%)', fontsize=10)
        
        plt.title('Disease Detection Accuracy by Disease Type')
        plt.xlabel('Disease')
        plt.ylabel('Accuracy')
        plt.xticks(rotation=45, ha='right')
        plt.ylim(0, 1.05)
        
        # Add accuracy values on top of bars
        for i, v in enumerate(accuracies):
            plt.text(i, v + 0.02, f"{v:.0%}", ha='center')
        
        plt.tight_layout()
        accuracy_chart_path = os.path.join(output_dir, "accuracy_by_disease.png")
        plt.savefig(accuracy_chart_path)
        plt.close()
        print(f"✓ Accuracy chart generated: {accuracy_chart_path}")
    
    # 2. Confusion matrix (simplified - just showing correct vs incorrect)
    if disease_results:
        # Count correct/incorrect detections for each disease
        disease_names = list(disease_results.keys())
        correct_counts = []
        incorrect_counts = []
        
        for disease, results in disease_results.items():
            correct = sum(1 for r in results if r.get('correct_detection', False))
            incorrect = len(results) - correct
            correct_counts.append(correct)
            incorrect_counts.append(incorrect)
        
        # Create stacked bar chart
        plt.figure(figsize=(12, 6))
        
        # Sort by correct percentage
        correct_pcts = [c/(c+i) if c+i > 0 else 0 for c, i in zip(correct_counts, incorrect_counts)]
        sorted_indices = np.argsort(correct_pcts)[::-1]
        
        disease_names = [disease_names[i] for i in sorted_indices]
        correct_counts = [correct_counts[i] for i in sorted_indices]
        incorrect_counts = [incorrect_counts[i] for i in sorted_indices]
        
        # Create stacked bar
        plt.bar(disease_names, correct_counts, label='Correct', color='green')
        plt.bar(disease_names, incorrect_counts, bottom=correct_counts, label='Incorrect', color='red')
        
        plt.title('Correct vs. Incorrect Detections by Disease')
        plt.xlabel('Disease')
        plt.ylabel('Number of Test Cases')
        plt.xticks(rotation=45, ha='right')
        plt.legend()
        
        # Add total count and percentage on top of bars
        for i in range(len(disease_names)):
            total = correct_counts[i] + incorrect_counts[i]
            pct = correct_counts[i] / total if total > 0 else 0
            plt.text(i, total + 0.1, f"{pct:.0%}", ha='center')
        
        plt.tight_layout()
        detection_chart_path = os.path.join(output_dir, "correct_vs_incorrect.png")
        plt.savefig(detection_chart_path)
        plt.close()
        print(f"✓ Detection chart generated: {detection_chart_path}")
    
    # 3. Confidence distribution
    if disease_results:
        plt.figure(figsize=(12, 6))
        
        for disease, results in disease_results.items():
            confidences = [r['confidence'] for r in results if r.get('analysis_success', False)]
            if confidences:
                plt.plot(range(len(confidences)), sorted(confidences), 'o-', label=disease)
        
        plt.title('Confidence Distribution by Disease')
        plt.xlabel('Test Case (sorted by confidence)')
        plt.ylabel('Confidence')
        plt.ylim(0, 1.05)
        plt.legend()
        plt.grid(True, alpha=0.3)
        
        plt.tight_layout()
        confidence_chart_path = os.path.join(output_dir, "confidence_distribution.png")
        plt.savefig(confidence_chart_path)
        plt.close()
        print(f"✓ Confidence chart generated: {confidence_chart_path}")
    
    return True

def generate_html_report(summary, disease_results, output_dir="test_reports"):
    """Generate an HTML report with all results and visualizations"""
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate visualizations first
    generate_visualizations(summary, disease_results, output_dir)
    
    # Create HTML report
    html_path = os.path.join(output_dir, "disease_test_report.html")
    
    with open(html_path, 'w') as f:
        f.write("""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Disease Detection Test Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1, h2, h3 { color: #2c3e50; }
                .container { max-width: 1200px; margin: 0 auto; }
                .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
                .chart { margin: 20px 0; text-align: center; }
                .chart img { max-width: 100%; border: 1px solid #ddd; border-radius: 5px; }
                table { border-collapse: collapse; width: 100%; margin: 20px 0; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
                tr:nth-child(even) { background-color: #f9f9f9; }
                .good { color: green; }
                .fair { color: orange; }
                .poor { color: red; }
                .details { margin-top: 30px; }
                .disease-section { margin-bottom: 30px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
                .test-case { background-color: #f8f9fa; padding: 10px; margin: 10px 0; border-radius: 5px; }
                .correct { border-left: 5px solid green; }
                .incorrect { border-left: 5px solid red; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Disease Detection Test Report</h1>
        """)
        
        # Add summary section
        f.write('<div class="summary">')
        if summary:
            f.write(f'<h2>Overall Summary</h2>')
            f.write(f'<p><strong>Overall Accuracy:</strong> {summary["accuracy"]:.2%} ({summary["total_correct"]}/{summary["total_tests"]} correct)</p>')
            
            # Add performance assessment
            if summary["accuracy"] >= 0.9:
                f.write('<p><strong>Performance Assessment:</strong> <span class="good">Excellent</span> - The system is performing very well across most diseases.</p>')
            elif summary["accuracy"] >= 0.7:
                f.write('<p><strong>Performance Assessment:</strong> <span class="fair">Good</span> - The system is performing adequately but has room for improvement.</p>')
            elif summary["accuracy"] >= 0.5:
                f.write('<p><strong>Performance Assessment:</strong> <span class="fair">Fair</span> - The system needs significant improvement for reliable clinical use.</p>')
            else:
                f.write('<p><strong>Performance Assessment:</strong> <span class="poor">Poor</span> - The system requires major improvements before it can be considered reliable.</p>')
        else:
            f.write('<p>No summary data available.</p>')
        f.write('</div>')
        
        # Add charts
        f.write('<div class="charts">')
        f.write('<h2>Performance Visualizations</h2>')
        
        f.write('<div class="chart">')
        f.write('<h3>Accuracy by Disease</h3>')
        f.write(f'<img src="accuracy_by_disease.png" alt="Accuracy by Disease">')
        f.write('</div>')
        
        f.write('<div class="chart">')
        f.write('<h3>Correct vs. Incorrect Detections</h3>')
        f.write(f'<img src="correct_vs_incorrect.png" alt="Correct vs. Incorrect Detections">')
        f.write('</div>')
        
        f.write('<div class="chart">')
        f.write('<h3>Confidence Distribution</h3>')
        f.write(f'<img src="confidence_distribution.png" alt="Confidence Distribution">')
        f.write('</div>')
        
        f.write('</div>')
        
        # Add disease results table
        f.write('<h2>Results by Disease</h2>')
        f.write('<table>')
        f.write('<tr><th>Disease</th><th>Accuracy</th><th>Correct/Total</th><th>Assessment</th></tr>')
        
        if summary:
            # Sort diseases by accuracy
            sorted_diseases = sorted(
                summary['results_by_disease'].items(),
                key=lambda x: x[1]['accuracy'],
                reverse=True
            )
            
            for disease, stats in sorted_diseases:
                accuracy = stats['accuracy']
                correct = stats['correct']
                total = stats['total']
                
                # Add assessment based on accuracy
                if accuracy >= 0.9:
                    assessment = '<span class="good">Excellent</span>'
                elif accuracy >= 0.7:
                    assessment = '<span class="fair">Good</span>'
                elif accuracy >= 0.5:
                    assessment = '<span class="fair">Fair</span>'
                else:
                    assessment = '<span class="poor">Poor</span>'
                
                f.write(f'<tr><td>{disease}</td><td>{accuracy:.2%}</td><td>{correct}/{total}</td><td>{assessment}</td></tr>')
        elif disease_results:
            # Calculate from disease_results
            for disease, results in disease_results.items():
                correct = sum(1 for r in results if r.get('correct_detection', False))
                total = len(results)
                accuracy = correct / total if total > 0 else 0
                
                # Add assessment based on accuracy
                if accuracy >= 0.9:
                    assessment = '<span class="good">Excellent</span>'
                elif accuracy >= 0.7:
                    assessment = '<span class="fair">Good</span>'
                elif accuracy >= 0.5:
                    assessment = '<span class="fair">Fair</span>'
                else:
                    assessment = '<span class="poor">Poor</span>'
                
                f.write(f'<tr><td>{disease}</td><td>{accuracy:.2%}</td><td>{correct}/{total}</td><td>{assessment}</td></tr>')
        
        f.write('</table>')
        
        # Add detailed results
        f.write('<div class="details">')
        f.write('<h2>Detailed Test Results</h2>')
        
        for disease, results in disease_results.items():
            f.write(f'<div class="disease-section">')
            f.write(f'<h3>Disease: {disease.upper()}</h3>')
            
            correct = sum(1 for r in results if r.get('correct_detection', False))
            total = len(results)
            accuracy = correct / total if total > 0 else 0
            
            f.write(f'<p>Accuracy: {accuracy:.2%} ({correct}/{total} correct)</p>')
            
            for i, result in enumerate(results):
                correct_class = "correct" if result.get('correct_detection', False) else "incorrect"
                f.write(f'<div class="test-case {correct_class}">')
                f.write(f'<h4>Test Case {i+1}: {os.path.basename(result["test_file"])}</h4>')
                f.write(f'<p><strong>Expected:</strong> {result["expected"]}</p>')
                f.write(f'<p><strong>Detected:</strong> {result["detected"]}</p>')
                f.write(f'<p><strong>Confidence:</strong> {result["confidence"]:.2%}</p>')
                f.write(f'<p><strong>Result:</strong> {"✓ Correct" if result.get("correct_detection", False) else "✗ Incorrect"}</p>')
                f.write('</div>')
            
            f.write('</div>')
        
        f.write('</div>')
        
        # Add recommendations
        f.write('<div class="recommendations">')
        f.write('<h2>Recommendations</h2>')
        
        # Generate recommendations based on results
        if summary:
            # Find worst performing diseases
            worst_diseases = sorted(
                summary['results_by_disease'].items(),
                key=lambda x: x[1]['accuracy']
            )[:3]
            
            if worst_diseases:
                f.write('<h3>Areas for Improvement</h3>')
                f.write('<ul>')
                for disease, stats in worst_diseases:
                    if stats['accuracy'] < 0.7:
                        f.write(f'<li><strong>{disease}</strong> - Current accuracy: {stats["accuracy"]:.2%}. Consider improving the model\'s ability to detect this condition.</li>')
                f.write('</ul>')
            
            # Overall recommendations
            f.write('<h3>General Recommendations</h3>')
            f.write('<ul>')
            
            if summary['accuracy'] < 0.7:
                f.write('<li>The overall accuracy is below the recommended threshold for medical applications. Consider retraining the model with more diverse data.</li>')
            
            if any(stats['accuracy'] < 0.5 for stats in summary['results_by_disease'].values()):
                f.write('<li>Some diseases have very poor detection rates. Consider specialized training for these conditions.</li>')
            
            f.write('<li>Continue testing with more varied test cases to ensure robustness.</li>')
            f.write('<li>Consider adding more variations of disease patterns that were poorly detected.</li>')
            f.write('</ul>')
        
        f.write('</div>')
        
        f.write("""
            </div>
        </body>
        </html>
        """)
    
    print(f"✓ HTML report generated: {html_path}")
    return html_path

def main():
    """Main function"""
    print("📊 Disease Test Results Analyzer")
    print("=" * 40)
    
    # Default results directory
    results_dir = "test_results"
    if len(sys.argv) >= 2:
        results_dir = sys.argv[1]
    
    # Default output directory
    output_dir = "test_reports"
    if len(sys.argv) >= 3:
        output_dir = sys.argv[2]
    
    print(f"Loading test results from: {results_dir}")
    summary, disease_results = load_test_results(results_dir)
    
    if not disease_results:
        print("No test results found. Run the tests first:")
        print("  python run_disease_test_cases.py --all")
        return
    
    print(f"Found results for {len(disease_results)} diseases")
    
    # Generate reports
    print("\nGenerating reports...")
    report_path = generate_accuracy_report(summary, disease_results, output_dir)
    generate_visualizations(summary, disease_results, output_dir)
    html_path = generate_html_report(summary, disease_results, output_dir)
    
    print("\n✅ Analysis complete!")
    print(f"Text report: {report_path}")
    print(f"HTML report: {html_path}")
    print(f"Visualizations saved to: {output_dir}")
    
    print("\nNext steps:")
    print("1. Review the HTML report for a comprehensive analysis")
    print("2. Check the accuracy report for detailed results")
    print("3. Use the visualizations to identify areas for improvement")
    print("4. Focus on improving detection for poorly performing diseases")

if __name__ == "__main__":
    main()
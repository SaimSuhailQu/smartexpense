import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/loan.dart';
import 'package:smartexpense/services/loan_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/widgets/loan_card.dart';
import 'package:smartexpense/screens/loan_details_screen.dart';

class LoansTabContent extends StatefulWidget {
  const LoansTabContent({super.key});

  @override
  State<LoansTabContent> createState() => _LoansTabContentState();
}

class _LoansTabContentState extends State<LoansTabContent> {
  @override
  Widget build(BuildContext context) {
    final loanService = Provider.of<LoanService>(context);
    final currencyService = Provider.of<CurrencyService>(context);
    
    return StreamBuilder<List<Loan>>(
      stream: loanService.getLoansStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final loans = snapshot.data ?? [];
        
        // Calculate total borrowed and lent
        double totalBorrowed = 0;
        double totalLent = 0;
        
        for (final loan in loans) {
          if (loan.type == 'borrowed') {
            totalBorrowed += loan.remainingAmount;
          } else {
            totalLent += loan.remainingAmount;
          }
        }
        
        return Column(
          children: [
            // Summary Cards
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Total Borrowed',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyService.formatAmountWithDecimal(totalBorrowed),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Total Lent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyService.formatAmountWithDecimal(totalLent),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loans List
            loans.isEmpty
                ? const Center(
                    child: Text(
                      'No loans found. Add a new loan to get started.',
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoanDetailsScreen(loan: loan),
                            ),
                          );
                        },
                        child: LoanCard(loan: loan),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }
}

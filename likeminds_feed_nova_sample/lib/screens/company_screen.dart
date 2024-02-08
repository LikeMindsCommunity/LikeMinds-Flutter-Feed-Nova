import 'package:flutter/material.dart';
import 'package:likeminds_feed_flutter_core/likeminds_feed_core.dart';
import 'package:likeminds_feed_nova_fl/likeminds_feed_nova_fl.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  LMCompanyViewData dummyCompany = (LMCompanyViewDataBuilder()
        ..id('123456789')
        ..name('Apple')
        ..imageUrl(
            'https://www.apple.com/ac/structured-data/images/knowledge_graph_logo.png?202208080158')
        ..description(
            'Discover the innovative world of Apple and shop everything iPhone, iPad, Apple Watch, Mac, and Apple TV, plus explore accessories, entertainment and expert'))
      .build();

  @override
  void initState() {
    super.initState();
    // TODO Nova: Replace with your own Company Object
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Company Profile'),
        backgroundColor: ColorTheme.backgroundColor,
      ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
            backgroundColor: ColorTheme.primaryColor,
            child: const Icon(Icons.add),
            onPressed: () async {
              GetWidgetRequest request = (GetWidgetRequestBuilder()
                    ..page(1)
                    ..pageSize(10)
                    ..searchKey("metadata.company_id")
                    ..searchValue(dummyCompany.id))
                  .build();
              GetWidgetResponse response =
                  await LMFeedCore.client.getWidgets(request);
              Map<String, dynamic> meta = dummyCompany.toJson();
              if (response.success) {
                String? id = response.widgets?.first.id;
                meta['entity_id'] = id;
              }
              LMAttachmentViewData attachmentViewData =
                  (LMAttachmentViewDataBuilder()
                        ..attachmentType(5)
                        ..attachmentMeta((LMAttachmentMetaViewDataBuilder()
                              ..meta(meta))
                            .build()))
                      .build();
              // ignore: use_build_context_synchronously
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LMFeedComposeScreen(
                    displayName: dummyCompany.name,
                    displayUrl: dummyCompany.imageUrl,
                    attachments: [attachmentViewData],
                  ),
                ),
              );
            }),
      ),
      body: CustomScrollView(
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),

          SliverToBoxAdapter(
            child: Center(
              child: CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage(dummyCompany.imageUrl ?? ''),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  dummyCompany.name ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontFamily: 'Gantari',
                    fontWeight: FontWeight.bold,
                    color: ColorTheme.lightWhite300,
                  ),
                ),
              ),
            ),
          ),

          // User Description
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                dummyCompany.description ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ColorTheme.lightWhite300,
                  fontFamily: 'Gantari',
                ),
              ),
            ),
          ),
          NovaLMFeedCompanyFeedWidget(
            companyId: dummyCompany.id,
            postBuilder: (context, postWidget, postViewData) {
              return novaPostBuilder(context, postWidget, postViewData, true);
            },
          ),
        ],
      ),
    );
  }
}

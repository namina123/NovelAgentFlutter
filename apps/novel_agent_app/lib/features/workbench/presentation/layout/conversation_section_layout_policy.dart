import 'conversation_section_id.dart';
import 'conversation_section_layout.dart';
import 'conversation_section_slot.dart';
import 'section_placement.dart';

class ConversationSectionLayoutPolicy {
  const ConversationSectionLayoutPolicy._();

  static const ConversationSectionLayout defaultLayout =
      ConversationSectionLayout(
        slotSpecs: [
          ConversationSectionSlotSpec(slotId: ConversationSectionSlot.header),
          ConversationSectionSlotSpec(slotId: ConversationSectionSlot.status),
          ConversationSectionSlotSpec(
            slotId: ConversationSectionSlot.body,
            expand: true,
          ),
          ConversationSectionSlotSpec(slotId: ConversationSectionSlot.appendix),
          ConversationSectionSlotSpec(slotId: ConversationSectionSlot.composer),
          ConversationSectionSlotSpec(
            slotId: ConversationSectionSlot.composerAccessory,
          ),
        ],
        placements: [
          SectionPlacement(
            sectionId: ConversationSectionId.panelHeader,
            slotId: ConversationSectionSlot.header,
            order: 0,
          ),
          SectionPlacement(
            sectionId: ConversationSectionId.runtimeStatus,
            slotId: ConversationSectionSlot.status,
            order: 0,
          ),
          SectionPlacement(
            sectionId: ConversationSectionId.timeline,
            slotId: ConversationSectionSlot.body,
            order: 0,
          ),
          SectionPlacement(
            sectionId: ConversationSectionId.pendingInput,
            slotId: ConversationSectionSlot.appendix,
            order: 0,
          ),
          SectionPlacement(
            sectionId: ConversationSectionId.composer,
            slotId: ConversationSectionSlot.composer,
            order: 0,
          ),
          SectionPlacement(
            sectionId: ConversationSectionId.modelStrip,
            slotId: ConversationSectionSlot.composerAccessory,
            order: 0,
          ),
        ],
      );
}

import { WorkspaceDialogService } from '@affine/core/modules/dialogs';
import { DocDisplayMetaService } from '@affine/core/modules/doc-display-meta';
import { JournalService } from '@affine/core/modules/journal';
import { I18n } from '@affine/i18n';
import { track } from '@affine/track';
import type { EditorHost } from '@blocksuite/affine/block-std';
import type {
  AffineInlineEditor,
  LinkedWidgetConfig,
} from '@blocksuite/affine/blocks';
import { LinkedWidgetUtils } from '@blocksuite/affine/blocks';
import type { DocMeta } from '@blocksuite/affine/store';
import { type FrameworkProvider, WorkspaceService } from '@toeverything/infra';

function createNewDocMenuGroup(
  framework: FrameworkProvider,
  query: string,
  abort: () => void,
  editorHost: EditorHost,
  inlineEditor: AffineInlineEditor
) {
  const originalNewDocMenuGroup = LinkedWidgetUtils.createNewDocMenuGroup(
    query,
    abort,
    editorHost,
    inlineEditor
  );

  // Patch the import item, to use the custom import dialog.
  const importItemIndex = originalNewDocMenuGroup.items.findIndex(
    item => item.key === 'import'
  );
  if (importItemIndex === -1) {
    return originalNewDocMenuGroup;
  }

  const originalItems = originalNewDocMenuGroup.items;
  const originalImportItem = originalItems[importItemIndex];
  const customImportItem = {
    ...originalImportItem,
    action: () => {
      abort();
      track.doc.editor.atMenu.import();
      framework
        .get(WorkspaceDialogService)
        .open('import', undefined, payload => {
          if (!payload) {
            return;
          }

          // If the imported file is a workspace file, insert the entry page node.
          const { docIds, entryId, isWorkspaceFile } = payload;
          if (isWorkspaceFile && entryId) {
            LinkedWidgetUtils.insertLinkedNode({
              inlineEditor,
              docId: entryId,
            });
            return;
          }

          // Otherwise, insert all the doc nodes.
          for (const docId of docIds) {
            LinkedWidgetUtils.insertLinkedNode({
              inlineEditor,
              docId,
            });
          }
        });
    },
  };

  // only replace the original import item
  originalItems.splice(importItemIndex, 1, customImportItem);
  return originalNewDocMenuGroup;
}

// TODO: fix the type
export function createLinkedWidgetConfig(
  framework: FrameworkProvider
): Partial<LinkedWidgetConfig> {
  return {
    getMenus: (
      query: string,
      abort: () => void,
      editorHost: EditorHost,
      inlineEditor: AffineInlineEditor
    ) => {
      const currentWorkspace = framework.get(WorkspaceService).workspace;
      const rawMetas = currentWorkspace.docCollection.meta.docMetas;
      const journalService = framework.get(JournalService);
      const isJournal = (d: DocMeta) =>
        !!journalService.journalDate$(d.id).value;

      const docDisplayMetaService = framework.get(DocDisplayMetaService);
      const docMetas = rawMetas
        .filter(meta => {
          if (isJournal(meta) && !meta.updatedDate) {
            return false;
          }
          return !meta.trash;
        })
        .map(meta => {
          const title = docDisplayMetaService.title$(meta.id, {
            reference: true,
          }).value;
          return {
            ...meta,
            title: I18n.t(title),
          };
        })
        .filter(({ title }) => isFuzzyMatch(title, query));

      // TODO need i18n if BlockSuite supported
      const MAX_DOCS = 6;
      return Promise.resolve([
        {
          name: 'Link to Doc',
          items: docMetas.map(doc => ({
            key: doc.id,
            name: doc.title,
            icon: docDisplayMetaService
              .icon$(doc.id, {
                type: 'lit',
                reference: true,
              })
              .value(),
            action: () => {
              abort();
              LinkedWidgetUtils.insertLinkedNode({
                inlineEditor,
                docId: doc.id,
              });
              track.doc.editor.atMenu.linkDoc();
            },
          })),
          maxDisplay: MAX_DOCS,
          overflowText: `${docMetas.length - MAX_DOCS} more docs`,
        },
        createNewDocMenuGroup(
          framework,
          query,
          abort,
          editorHost,
          inlineEditor
        ),
      ]);
    },
    mobile: {
      useScreenHeight: BUILD_CONFIG.isIOS,
      scrollContainer: window,
      scrollTopOffset: () => {
        const header = document.querySelector('header');
        if (!header) return 0;

        const { y, height } = header.getBoundingClientRect();
        return y + height;
      },
    },
  };
}

/**
 * Checks if the name is a fuzzy match of the query.
 *
 * @example
 * ```ts
 * const name = 'John Smith';
 * const query = 'js';
 * const isMatch = isFuzzyMatch(name, query);
 * // isMatch: true
 * ```
 */
function isFuzzyMatch(name: string, query: string) {
  const pureName = name
    .trim()
    .toLowerCase()
    .split('')
    .filter(char => char !== ' ')
    .join('');

  const regex = new RegExp(
    query
      .split('')
      .filter(char => char !== ' ')
      .map(item => `${escapeRegExp(item)}.*`)
      .join(''),
    'i'
  );
  return regex.test(pureName);
}

function escapeRegExp(input: string) {
  // escape regex characters in the input string to prevent regex format errors
  return input.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

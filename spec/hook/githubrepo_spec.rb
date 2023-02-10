require 'spec_helper'
require 'rugged'
require 'oxidized/hook/githubrepo'

describe GithubRepo do
  let(:credentials) { mock }
  let(:remote) { mock }
  let(:remotes) { mock }
  let(:repo_head) { mock }
  let(:repo) { mock }
  let(:gr) { GithubRepo.new }

  before do
    Oxidized.asetus = Asetus.new
    Oxidized.config.log = '/dev/null'
    Oxidized.setup_logger
    Oxidized.config.output.default = 'git'
  end

  describe '#validate_cfg!' do
    before do
      gr.expects(:respond_to?).with(:validate_cfg!).returns(false) # `cfg=` call
    end

    it 'raise a error when `remote_repo` is not configured' do
      Oxidized.config.hooks.github_repo_hook = { type: 'githubrepo' }
      gr.cfg = Oxidized.config.hooks.github_repo_hook
      proc { gr.validate_cfg! }.must_raise(KeyError)
    end
  end

  describe "#fetch_and_merge_remote" do
    before(:each) do
      Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
      repo_head.expects(:name).returns('refs/heads/master')
      gr.cfg = Oxidized.config.hooks.github_repo_hook
    end

    it "should not try to merge when there is no update in remote branch" do
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))
      repo.expects(:branches).never
      repo.expects(:head).returns(repo_head)
      gr.fetch_and_merge_remote(repo, credentials).must_equal nil
    end
    describe "when there is update considering conflicts" do
      let(:merge_index) { mock }
      let(:their_branch) { mock }

      before(:each) do
        repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(total_deltas: 1)
        their_branch.expects(:target_id).returns(1)
        repo_head.expects(:target_id).returns(2)
        repo.expects(:merge_commits).with(2, 1).returns(merge_index)
        repo.expects(:branches).returns("origin/master" => their_branch)
      end

      it "should not try merging when there's conflict" do
        repo.expects(:head).twice.returns(repo_head)
        their_branch.expects(:name).returns("origin/master")
        merge_index.expects(:conflicts?).returns(true)
        Rugged::Commit.expects(:create).never
        gr.fetch_and_merge_remote(repo, credentials).must_equal nil
      end

      it "should merge when there is no conflict" do
        repo.expects(:head).times(3).returns(repo_head)
        their_branch.expects(:target).returns("their_target")
        their_branch.expects(:name).twice.returns("origin/master")
        repo_head.expects(:target).returns("our_target")
        merge_index.expects(:write_tree).with(repo).returns("tree")
        merge_index.expects(:conflicts?).returns(false)
        Rugged::Commit.expects(:create).with(repo,
                                             parents:    %w[our_target their_target],
                                             tree:       "tree",
                                             message:    "Merge remote-tracking branch 'origin/master'",
                                             update_ref: "HEAD").returns(1)
        gr.fetch_and_merge_remote(repo, credentials).must_equal 1
      end
    end
  end

  describe "#run_hook" do
    let(:group) { nil }
    let(:ctx) { OpenStruct.new(node: node) }
    let(:node) do
      Oxidized::Node.new(ip: '127.0.0.1', group: group, model: 'junos', output: 'git')
    end

    before do
      gr.stubs(:credentials).returns(credentials)
      repo_head.expects(:name).at_least_once().returns('refs/heads/master')
      repo.expects(:head).at_least_once().returns(repo_head)
      repo.expects(:path).at_least_once().returns('/foo.git')
      repo.expects(:fetch).with('origin', ['refs/heads/master'], credentials: credentials).returns(Hash.new(0))
      repo.expects(:remotes).at_least_once().returns(remotes)
    end

    describe 'when there is only one repository and no groups' do
      before do
        Oxidized.config.output.git.repo = '/foo.git'
        remotes.expects(:[]).at_least_once().with('origin').returns(remote)
        remote.expects(:push).with(['refs/heads/master'], credentials: credentials).returns(true)
        Rugged::Repository.expects(:new).with('/foo.git').returns(repo)
      end

      it "will push to the remote repository using https" do
        Oxidized.config.hooks.github_repo_hook.remote_repo = 'https://github.com/username/foo.git'
        Oxidized.config.hooks.github_repo_hook.username = 'username'
        Oxidized.config.hooks.github_repo_hook.password = 'password'
        gr.cfg = Oxidized.config.hooks.github_repo_hook
        remote.expects(:url).at_least_once().returns('https://github.com/username/foo.git')
        gr.run_hook(ctx).must_equal true
      end

      it "will set the remote to the URL from configuration" do
        Oxidized.config.hooks.github_repo_hook.remote_repo = 'https://github.com/username/foo.git'
        Oxidized.config.hooks.github_repo_hook.username = 'username'
        Oxidized.config.hooks.github_repo_hook.password = 'password'
        gr.cfg = Oxidized.config.hooks.github_repo_hook
        remote.expects(:url).at_least_once().returns('https://github.com/username/foo_old.git')
        remotes.expects(:set_url).with("origin", Oxidized.config.hooks.github_repo_hook.remote_repo)
        gr.run_hook(ctx).must_equal true
      end

      it "will push to the remote repository using ssh" do
        Oxidized.config.hooks.github_repo_hook.remote_repo = 'git@github.com:username/foo.git'
        gr.cfg = Oxidized.config.hooks.github_repo_hook
        remote.expects(:url).at_least_once().returns('git@github.com:username/foo.git')
        gr.run_hook(ctx).must_equal true
      end
    end

    describe "when there are groups" do
      let(:group) { 'ggrroouupp' }

      before do
        Rugged::Repository.expects(:new).with(repository).returns(repo)

        remote.expects(:push).with(['refs/heads/master'], credentials: credentials).returns(true)
        remotes.expects(:create).with('origin', create_remote).returns(remote)
        remotes.expects(:[]).with('origin').returns(nil).then.at_least_once().returns(remote)
      end

      describe 'and there are several repositories' do
        let(:create_remote) { 'ggrroouupp#remote_repo' }
        let(:repository) { '/ggrroouupp.git' }

        before do
          Oxidized.config.output.git.repo.ggrroouupp = repository
          Oxidized.config.hooks.github_repo_hook.remote_repo.ggrroouupp = 'ggrroouupp#remote_repo'
        end

        it 'will push to the node group repository' do
          gr.cfg = Oxidized.config.hooks.github_repo_hook
          gr.run_hook(ctx).must_equal true
        end
      end

      describe 'and has a single repository' do
        let(:create_remote) { 'github_repo_hook#remote_repo' }
        let(:repository) { '/foo.git' }

        before do
          Oxidized.config.output.git.repo = repository
          Oxidized.config.hooks.github_repo_hook.remote_repo = 'github_repo_hook#remote_repo'
          Oxidized.config.output.git.single_repo = true
        end

        it 'will push to the correct repository' do
          gr.cfg = Oxidized.config.hooks.github_repo_hook
          gr.run_hook(ctx).must_equal true
        end
      end
    end
  end
end
